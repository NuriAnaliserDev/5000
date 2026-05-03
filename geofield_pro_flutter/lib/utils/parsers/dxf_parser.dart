import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../models/boundary_polygon.dart';
import 'dxf_coordinate_inference.dart';
import '../../core/error/app_error.dart';

class DxfParser {
  static List<BoundaryPolygon> parse(
    String content,
    String filename, {
    double? hintLatitude,
    double? hintLongitude,
  }) {
    try {
      final lead = content.trimLeft();
      if (lead.startsWith('AutoCAD Binary DXF')) {
        throw AppError(
            'Binary DXF is not supported. Save as ASCII DXF from your CAD software and try again.',
            category: ErrorCategory.validation);
      }
      final normalized = content
          .replaceAll('\r\n', '\n')
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final entities = <Map<String, List<String>>>[];

      Map<String, List<String>>? current;
      for (int i = 0; i + 1 < normalized.length; i += 2) {
        final code = normalized[i].trim();
        final value = normalized[i + 1].trim();
        if (code == '0') {
          if (current != null && current['__type'] != null) {
            entities.add(current);
          }
          current = {
            '__type': [value.toUpperCase()],
          };
          continue;
        }
        if (current == null) continue;
        current.putIfAbsent(code, () => <String>[]).add(value);
      }
      if (current != null && current['__type'] != null) {
        entities.add(current);
      }

      final expanded = _expandClassicPolylines(entities);

      final blockDefs = <String, Map<String, dynamic>>{};
      bool inBlock = false;
      String? currentBlockName;

      for (final entity in expanded) {
        final type = entity['__type']!.first;
        if (type == 'BLOCK') {
          final name = entity['2']?.first;
          if (name == null || name.isEmpty || name.startsWith('*')) {
            inBlock = true;
            currentBlockName = null;
            continue;
          }
          inBlock = true;
          currentBlockName = name;
          final baseX = double.tryParse((entity['10']?.first ?? '')) ?? 0.0;
          final baseY = double.tryParse((entity['20']?.first ?? '')) ?? 0.0;
          blockDefs[name] = {
            'baseX': baseX,
            'baseY': baseY,
            'geometries': <List<LatLng>>[],
          };
          continue;
        }

        if (type == 'ENDBLK') {
          inBlock = false;
          currentBlockName = null;
          continue;
        }

        if (!inBlock || currentBlockName == null) continue;
        final points = _pointsFromDxfEntity(entity, blockDefs: const {});
        if (points.length < 2) continue;

        final baseX = blockDefs[currentBlockName]!['baseX'] as double;
        final baseY = blockDefs[currentBlockName]!['baseY'] as double;
        final local = points
            .map((p) => LatLng(p.latitude - baseY, p.longitude - baseX))
            .toList();
        (blockDefs[currentBlockName]!['geometries'] as List<List<LatLng>>)
            .add(local);
      }

      final extracted = <BoundaryPolygon>[];
      inBlock = false;
      for (final entity in expanded) {
        final type = entity['__type']!.first;
        if (type == 'BLOCK') {
          inBlock = true;
          continue;
        }
        if (type == 'ENDBLK') {
          inBlock = false;
          continue;
        }
        if (inBlock) continue;

        final points = _pointsFromDxfEntity(entity, blockDefs: blockDefs);

        if (points.length < 2) continue;
        extracted.add(BoundaryPolygon(
          name: 'DXF Chizma ${extracted.length + 1}',
          points: points,
          sourceFile: filename,
          zoneType: ZoneType.base,
        ));
      }

      return DxfCoordinateInference.applyHints(
        extracted,
        hintLat: hintLatitude,
        hintLng: hintLongitude,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError('DXF oqishda xatolik: $e',
          category: ErrorCategory.validation);
    }
  }

  /// Avtokad klassik `POLYLINE` + `VERTEX` + `SEQEND` zanjirini LWPOLYLINE-ga aylantiradi.
  static List<Map<String, List<String>>> _expandClassicPolylines(
    List<Map<String, List<String>>> entities,
  ) {
    final out = <Map<String, List<String>>>[];
    for (var i = 0; i < entities.length; i++) {
      final e = entities[i];
      final t = e['__type']!.first;
      if (t == 'POLYLINE') {
        final seqEndIdx = _findSeqEndAfterPolyline(entities, i);
        if (seqEndIdx != null) {
          final syn = _classicPolylineToLw(e, entities, i + 1, seqEndIdx);
          if (syn != null) {
            out.add(syn);
            i = seqEndIdx;
            continue;
          }
        }
      }
      if (t == 'VERTEX' || t == 'SEQEND') {
        continue;
      }
      out.add(e);
    }
    return out;
  }

  /// `POLYLINE` dan keyin faqat `VERTEX` va oxirida `SEQEND` bo‘lsa, `SEQEND` indeksi.
  static int? _findSeqEndAfterPolyline(
    List<Map<String, List<String>>> entities,
    int polylineIndex,
  ) {
    if (polylineIndex >= entities.length) return null;
    if (entities[polylineIndex]['__type']!.first != 'POLYLINE') return null;
    var j = polylineIndex + 1;
    while (j < entities.length) {
      final t = entities[j]['__type']!.first;
      if (t == 'VERTEX') {
        j++;
      } else if (t == 'SEQEND') {
        return j;
      } else {
        return null;
      }
    }
    return null;
  }

  static Map<String, List<String>>? _classicPolylineToLw(
    Map<String, List<String>> polyEnt,
    List<Map<String, List<String>>> entities,
    int firstVertexIndex,
    int seqEndIndex,
  ) {
    final xs = <String>[];
    final ys = <String>[];
    final bulges = <String>[];
    for (var j = firstVertexIndex; j < seqEndIndex; j++) {
      if (entities[j]['__type']!.first != 'VERTEX') return null;
      final vx = entities[j]['10']?.first;
      final vy = entities[j]['20']?.first;
      if (vx == null || vy == null) continue;
      xs.add(vx);
      ys.add(vy);
      final b = entities[j]['42']?.first;
      bulges.add((b != null && b.isNotEmpty) ? b : '0');
    }
    if (xs.length < 2) return null;
    final flags = polyEnt['70'] ?? ['0'];
    return {
      '__type': ['LWPOLYLINE'],
      '10': xs,
      '20': ys,
      '70': flags,
      '42': bulges,
    };
  }

  static List<LatLng> _pointsFromDxfEntity(
    Map<String, List<String>> entity, {
    required Map<String, Map<String, dynamic>> blockDefs,
  }) {
    final type = entity['__type']!.first;
    return switch (type) {
      'LWPOLYLINE' || 'POLYLINE' => _dxfPolylinePoints(entity),
      'LINE' => _dxfLinePoints(entity),
      'CIRCLE' => _dxfCirclePoints(entity),
      'ARC' => _dxfArcPoints(entity),
      'ELLIPSE' => _dxfEllipsePoints(entity),
      'SPLINE' => _dxfSplinePoints(entity),
      'INSERT' => _dxfInsertPoints(entity, blockDefs),
      'HATCH' => _dxfHatchPoints(entity),
      'TEXT' || 'MTEXT' => _dxfTextAnchorPoint(entity),
      _ => const <LatLng>[],
    };
  }

  static List<LatLng> _dxfPolylinePoints(Map<String, List<String>> entity) {
    final xs = entity['10'] ?? const <String>[];
    final ys = entity['20'] ?? const <String>[];
    final bulges = entity['42'] ?? const <String>[];
    final len = math.min(xs.length, ys.length);
    final rawPoints = <LatLng>[];
    for (int i = 0; i < len; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) {
        rawPoints.add(LatLng(y, x));
      }
    }

    if (rawPoints.length < 2) return rawPoints;

    final flags = int.tryParse((entity['70']?.first ?? '0'));
    final isClosed = flags != null && (flags & 1) == 1;

    final points = <LatLng>[];
    for (int i = 0; i < rawPoints.length - 1; i++) {
      final start = rawPoints[i];
      final end = rawPoints[i + 1];
      if (points.isEmpty) {
        points.add(start);
      }

      final bulge =
          i < bulges.length ? (double.tryParse(bulges[i]) ?? 0.0) : 0.0;
      if (bulge.abs() < 1e-9) {
        points.add(end);
      } else {
        points.addAll(_buildBulgeArcPoints(start, end, bulge));
      }
    }

    if (isClosed && rawPoints.length > 2) {
      final start = rawPoints.last;
      final end = rawPoints.first;
      final closeBulgeIndex = rawPoints.length - 1;
      final closeBulge = closeBulgeIndex < bulges.length
          ? (double.tryParse(bulges[closeBulgeIndex]) ?? 0.0)
          : 0.0;

      if (closeBulge.abs() < 1e-9) {
        points.add(end);
      } else {
        points.addAll(_buildBulgeArcPoints(start, end, closeBulge));
      }
    }
    return points;
  }

  static List<LatLng> _buildBulgeArcPoints(
      LatLng start, LatLng end, double bulge) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    final chord = math.sqrt(dx * dx + dy * dy);
    if (chord < 1e-12) return [end];

    final theta = 4.0 * math.atan(bulge);
    if (theta.abs() < 1e-9) return [end];
    final radius = (chord / 2.0) / math.sin(theta.abs() / 2.0);

    final midX = (start.longitude + end.longitude) / 2.0;
    final midY = (start.latitude + end.latitude) / 2.0;
    final ux = dx / chord;
    final uy = dy / chord;
    final leftNx = -uy;
    final leftNy = ux;

    final h2 = (radius * radius) - (chord * chord / 4.0);
    final h = h2 <= 0 ? 0.0 : math.sqrt(h2);
    final sign = bulge >= 0 ? 1.0 : -1.0;
    final cx = midX + leftNx * h * sign;
    final cy = midY + leftNy * h * sign;

    final startA = math.atan2(start.latitude - cy, start.longitude - cx);
    final endA = math.atan2(end.latitude - cy, end.longitude - cx);

    double sweep = endA - startA;
    if (bulge >= 0 && sweep < 0) sweep += 2 * math.pi;
    if (bulge < 0 && sweep > 0) sweep -= 2 * math.pi;

    final segments = math.max(8, (sweep.abs() * 18 / math.pi).ceil());
    final points = <LatLng>[];
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final a = startA + sweep * t;
      final x = cx + radius * math.cos(a);
      final y = cy + radius * math.sin(a);
      points.add(LatLng(y, x));
    }
    return points;
  }

  static List<LatLng> _dxfLinePoints(Map<String, List<String>> entity) {
    final x1 = double.tryParse((entity['10']?.first ?? ''));
    final y1 = double.tryParse((entity['20']?.first ?? ''));
    final x2 = double.tryParse((entity['11']?.first ?? ''));
    final y2 = double.tryParse((entity['21']?.first ?? ''));
    if (x1 == null || y1 == null || x2 == null || y2 == null) {
      return const <LatLng>[];
    }
    return [LatLng(y1, x1), LatLng(y2, x2)];
  }

  static List<LatLng> _dxfCirclePoints(Map<String, List<String>> entity) {
    final cx = double.tryParse((entity['10']?.first ?? ''));
    final cy = double.tryParse((entity['20']?.first ?? ''));
    final r = double.tryParse((entity['40']?.first ?? ''));
    if (cx == null || cy == null || r == null || r <= 0) {
      return const <LatLng>[];
    }
    return _buildArcPoints(cx, cy, r, 0, 360);
  }

  static List<LatLng> _dxfArcPoints(Map<String, List<String>> entity) {
    final cx = double.tryParse((entity['10']?.first ?? ''));
    final cy = double.tryParse((entity['20']?.first ?? ''));
    final r = double.tryParse((entity['40']?.first ?? ''));
    final startDeg = double.tryParse((entity['50']?.first ?? ''));
    final endDeg = double.tryParse((entity['51']?.first ?? ''));
    if (cx == null ||
        cy == null ||
        r == null ||
        r <= 0 ||
        startDeg == null ||
        endDeg == null) {
      return const <LatLng>[];
    }
    return _buildArcPoints(cx, cy, r, startDeg, endDeg);
  }

  static List<LatLng> _dxfSplinePoints(Map<String, List<String>> entity) {
    final xs = entity['10'] ?? const <String>[];
    final ys = entity['20'] ?? const <String>[];
    final len = math.min(xs.length, ys.length);
    final points = <LatLng>[];
    for (int i = 0; i < len; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) {
        points.add(LatLng(y, x));
      }
    }

    if (points.length >= 2) return points;

    final fitXs = entity['11'] ?? const <String>[];
    final fitYs = entity['21'] ?? const <String>[];
    final fitLen = math.min(fitXs.length, fitYs.length);
    for (int i = 0; i < fitLen; i++) {
      final x = double.tryParse(fitXs[i]);
      final y = double.tryParse(fitYs[i]);
      if (x != null && y != null) {
        points.add(LatLng(y, x));
      }
    }
    return points;
  }

  static List<LatLng> _dxfEllipsePoints(Map<String, List<String>> entity) {
    final cx = double.tryParse((entity['10']?.first ?? ''));
    final cy = double.tryParse((entity['20']?.first ?? ''));
    final majorX = double.tryParse((entity['11']?.first ?? ''));
    final majorY = double.tryParse((entity['21']?.first ?? ''));
    final ratio = double.tryParse((entity['40']?.first ?? ''));
    final startParam = double.tryParse((entity['41']?.first ?? '')) ?? 0.0;
    final endParam =
        double.tryParse((entity['42']?.first ?? '')) ?? (2 * math.pi);

    if (cx == null ||
        cy == null ||
        majorX == null ||
        majorY == null ||
        ratio == null ||
        ratio <= 0) {
      return const <LatLng>[];
    }

    final majorLen = math.sqrt(majorX * majorX + majorY * majorY);
    if (majorLen <= 0) return const <LatLng>[];
    final minorLen = majorLen * ratio;
    final ux = majorX / majorLen;
    final uy = majorY / majorLen;
    final vx = -uy;
    final vy = ux;

    double sweep = endParam - startParam;
    if (sweep <= 0) sweep += 2 * math.pi;
    final segments = math.max(24, (sweep * 24 / math.pi).ceil());

    final points = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final p = startParam + sweep * t;
      final px = cx + majorLen * math.cos(p) * ux + minorLen * math.sin(p) * vx;
      final py = cy + majorLen * math.cos(p) * uy + minorLen * math.sin(p) * vy;
      points.add(LatLng(py, px));
    }
    return points;
  }

  static List<LatLng> _dxfTextAnchorPoint(Map<String, List<String>> entity) {
    final x = double.tryParse((entity['10']?.first ?? ''));
    final y = double.tryParse((entity['20']?.first ?? ''));
    if (x == null || y == null) return const <LatLng>[];
    const eps = 0.000001;
    return [LatLng(y, x), LatLng(y + eps, x + eps)];
  }

  static List<LatLng> _dxfInsertPoints(
    Map<String, List<String>> entity,
    Map<String, Map<String, dynamic>> blockDefs,
  ) {
    final blockName = entity['2']?.first;
    if (blockName == null || blockName.isEmpty) return const <LatLng>[];
    final def = blockDefs[blockName];
    if (def == null) return const <LatLng>[];

    final insertionX = double.tryParse((entity['10']?.first ?? ''));
    final insertionY = double.tryParse((entity['20']?.first ?? ''));
    if (insertionX == null || insertionY == null) return const <LatLng>[];

    final scaleX = double.tryParse((entity['41']?.first ?? '')) ?? 1.0;
    final scaleY = double.tryParse((entity['42']?.first ?? '')) ?? 1.0;
    final rotationDeg = double.tryParse((entity['50']?.first ?? '')) ?? 0.0;
    final rowCount = int.tryParse((entity['71']?.first ?? '1')) ?? 1;
    final colCount = int.tryParse((entity['70']?.first ?? '1')) ?? 1;
    final rowSpacing = double.tryParse((entity['45']?.first ?? '0')) ?? 0.0;
    final colSpacing = double.tryParse((entity['44']?.first ?? '0')) ?? 0.0;
    final rot = rotationDeg * math.pi / 180.0;
    final cosR = math.cos(rot);
    final sinR = math.sin(rot);

    final geometries = def['geometries'] as List<List<LatLng>>;
    if (geometries.isEmpty) return const <LatLng>[];

    final flattened = <LatLng>[];
    final rows = math.max(1, rowCount);
    final cols = math.max(1, colCount);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final offsetX = c * colSpacing;
        final offsetY = r * rowSpacing;
        final arrX = offsetX * cosR - offsetY * sinR;
        final arrY = offsetX * sinR + offsetY * cosR;

        for (final geometry in geometries) {
          for (final p in geometry) {
            final localX = p.longitude * scaleX;
            final localY = p.latitude * scaleY;
            final rotX = localX * cosR - localY * sinR;
            final rotY = localX * sinR + localY * cosR;
            final worldX = insertionX + arrX + rotX;
            final worldY = insertionY + arrY + rotY;
            flattened.add(LatLng(worldY, worldX));
          }
        }
      }
    }
    return flattened;
  }

  static List<LatLng> _dxfHatchPoints(Map<String, List<String>> entity) {
    final xs = entity['10'] ?? const <String>[];
    final ys = entity['20'] ?? const <String>[];
    final len = math.min(xs.length, ys.length);
    if (len < 2) return const <LatLng>[];

    final points = <LatLng>[];
    for (int i = 0; i < len; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) {
        points.add(LatLng(y, x));
      }
    }
    if (points.length < 2) return const <LatLng>[];

    final first = points.first;
    final last = points.last;
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      points.add(first);
    }
    return points;
  }

  static List<LatLng> _buildArcPoints(
    double cx,
    double cy,
    double radius,
    double startDeg,
    double endDeg,
  ) {
    double normalizedStart = startDeg % 360;
    if (normalizedStart < 0) normalizedStart += 360;
    double normalizedEnd = endDeg % 360;
    if (normalizedEnd < 0) normalizedEnd += 360;
    double sweep = normalizedEnd - normalizedStart;
    if (sweep <= 0) sweep += 360;

    final segments = math.max(16, (sweep / 6).ceil());
    final points = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final ang = (normalizedStart + sweep * t) * math.pi / 180.0;
      final x = cx + radius * math.cos(ang);
      final y = cy + radius * math.sin(ang);
      points.add(LatLng(y, x));
    }
    return points;
  }
}
