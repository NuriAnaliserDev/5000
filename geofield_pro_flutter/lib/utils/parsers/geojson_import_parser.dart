import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';

/// GeoJSON (WGS-84) — Polygon, MultiPolygon, LineString, MultiLineString.
/// Boshqa geometriyalar o‘tkazib yuboriladi.
class GeojsonImportParser {
  static List<BoundaryPolygon> parse(String content, String filename) {
    final text = _stripBom(content).trim();
    final dynamic root = json.decode(text);
    if (root is! Map<String, dynamic>) return [];

    return _fromObject(root, filename);
  }

  static String _stripBom(String s) {
    if (s.isEmpty) return s;
    final cp = s.codeUnitAt(0);
    if (cp == 0xFEFF) return s.substring(1);
    return s;
  }

  static List<BoundaryPolygon> _fromObject(
    Map<String, dynamic> obj,
    String filename,
  ) {
    final t = obj['type'] as String?;
    if (t == 'FeatureCollection') {
      final features = obj['features'] as List<dynamic>?;
      if (features == null) return [];
      final out = <BoundaryPolygon>[];
      var n = 0;
      for (final f in features) {
        if (f is! Map<String, dynamic>) continue;
        out.addAll(_fromFeature(f, filename, n++));
      }
      return out;
    }
    if (t == 'Feature') {
      return _fromFeature(obj, filename, 0);
    }
    if (t != null) {
      final g = obj['geometry'];
      if (g is Map<String, dynamic>) {
        return _fromGeometry(
          g,
          (obj['name'] as String?) ?? 'GeoJSON',
          filename,
        );
      }
    }
    return [];
  }

  static List<BoundaryPolygon> _fromFeature(
    Map<String, dynamic> f,
    String filename,
    int index,
  ) {
    final props = f['properties'];
    var name = 'Import ${index + 1}';
    if (props is Map<String, dynamic>) {
      final n = props['name'] ?? props['Name'] ?? props['id'];
      if (n != null) name = n.toString();
    }
    final g = f['geometry'];
    if (g is! Map<String, dynamic>) return [];
    return _fromGeometry(g, name, filename);
  }

  static List<BoundaryPolygon> _fromGeometry(
    Map<String, dynamic> g,
    String name,
    String filename,
  ) {
    final t = g['coordinates'] as dynamic;
    final type = g['type'] as String?;
    if (type == 'Polygon' && t is List) {
      final ring = t.isNotEmpty ? t[0] as List<dynamic>? : null;
      if (ring == null) return [];
      return [_poly(name, _ringToLatLng(ring), filename, ZoneType.workArea)];
    }
    if (type == 'MultiPolygon' && t is List) {
      final out = <BoundaryPolygon>[];
      var i = 0;
      for (final poly in t) {
        if (poly is! List) continue;
        if (poly.isEmpty) continue;
        final r = poly[0] as List<dynamic>?;
        if (r == null) continue;
        out.add(
          _poly(
            i == 0 ? name : '$name ($i)',
            _ringToLatLng(r),
            filename,
            ZoneType.workArea,
          ),
        );
        i++;
      }
      return out;
    }
    if (type == 'LineString' && t is List) {
      final pts = _lineToLatLng(t);
      if (pts.length < 2) return [];
      return [
        _poly(
          '$name (Line)',
          pts,
          filename,
          ZoneType.base,
        ),
      ];
    }
    if (type == 'MultiLineString' && t is List) {
      final out = <BoundaryPolygon>[];
      var i = 0;
      for (final line in t) {
        if (line is! List) continue;
        final pts = _lineToLatLng(line);
        if (pts.length < 2) continue;
        out.add(
          _poly(
            i == 0 ? '$name (Line)' : '$name (Line $i)',
            pts,
            filename,
            ZoneType.base,
          ),
        );
        i++;
      }
      return out;
    }
    if (type == 'Point' && t is List && t.length >= 2) {
      final lng = (t[0] as num).toDouble();
      final lat = (t[1] as num).toDouble();
      const eps = 0.000002;
      return [
        _poly(
          '$name (Point)',
          [LatLng(lat, lng), LatLng(lat + eps, lng + eps)],
          filename,
          ZoneType.base,
        ),
      ];
    }
    if (type == 'GeometryCollection') {
      final geoms = g['geometries'] as List<dynamic>?;
      if (geoms == null) return [];
      final out = <BoundaryPolygon>[];
      var i = 0;
      for (final sub in geoms) {
        if (sub is! Map<String, dynamic>) continue;
        out.addAll(_fromGeometry(sub, '$name ($i)', filename));
        i++;
      }
      return out;
    }
    return [];
  }

  static List<LatLng> _ringToLatLng(List<dynamic> ring) {
    final o = <LatLng>[];
    for (final p in ring) {
      if (p is! List || p.length < 2) continue;
      o.add(
        LatLng(
          (p[1] as num).toDouble(),
          (p[0] as num).toDouble(),
        ),
      );
    }
    return o;
  }

  static List<LatLng> _lineToLatLng(List<dynamic> line) {
    final o = <LatLng>[];
    for (final p in line) {
      if (p is! List || p.length < 2) continue;
      o.add(
        LatLng(
          (p[1] as num).toDouble(),
          (p[0] as num).toDouble(),
        ),
      );
    }
    return o;
  }

  static BoundaryPolygon _poly(
    String name,
    List<LatLng> points,
    String filename,
    ZoneType zone,
  ) {
    return BoundaryPolygon(
      name: name,
      points: points,
      sourceFile: filename,
      description: 'GeoJSON: $filename',
      zoneType: zone,
    );
  }
}
