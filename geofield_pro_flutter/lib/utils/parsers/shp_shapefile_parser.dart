import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';

/// ESRI Shapefile (.shp) — faqat WGS-84 (EPSG:4326) yoki shu koordinatada
/// saqlangan pliklar uchun. Boshqa projeksiyada noto‘g‘ri joylashadi.
class ShpShapefileParser {
  static List<BoundaryPolygon> parse(Uint8List data, String filename) {
    if (data.length < 100) return const [];
    final bd = ByteData.sublistView(data);
    final fileCode = bd.getInt32(0, Endian.big);
    if (fileCode != 9994) return const [];
    final fileLengthWords = bd.getInt32(24, Endian.big);
    final fileBytes = fileLengthWords * 2;
    if (fileBytes > data.length || fileLengthWords < 50) {
      return const [];
    }
    var offset = 100;
    final out = <BoundaryPolygon>[];
    var n = 0;
    while (offset + 8 <= data.length) {
      bd.getInt32(offset, Endian.big);
      final contentLengthWords = bd.getInt32(offset + 4, Endian.big);
      offset += 8;
      final contentBytes = contentLengthWords * 2;
      if (contentBytes < 4 || offset + contentBytes > data.length) break;
      final partBd = ByteData.sublistView(data, offset, offset + contentBytes);
      final st = partBd.getInt32(0, Endian.little);
      offset += contentBytes;
      if (st == 0) {
        n++;
        continue;
      }
      if (st == 1) {
        if (contentBytes < 4 + 8 + 8) {
          n++;
          continue;
        }
        n++;
        continue;
      }
      if (st == 3) {
        out.addAll(
          _parsePolyline(
            partBd,
            filename,
            n,
            isPolygon: false,
          ),
        );
        n++;
        continue;
      }
      if (st == 5) {
        out.addAll(
          _parsePolyline(
            partBd,
            filename,
            n,
            isPolygon: true,
          ),
        );
        n++;
        continue;
      }
      n++;
    }
    return out;
  }

  static List<BoundaryPolygon> _parsePolyline(
    ByteData partBd,
    String filename,
    int index, {
    required bool isPolygon,
  }) {
    if (partBd.lengthInBytes < 4 + 32 + 8) return const [];
    var o = 4 + 4 * 8;
    final numParts = partBd.getInt32(o, Endian.little);
    o += 4;
    final numPoints = partBd.getInt32(o, Endian.little);
    o += 4;
    if (numParts < 1 || numPoints < 2) return const [];
    if (o + 4 * numParts + 16 * numPoints > partBd.lengthInBytes) {
      return const [];
    }
    final parts = List<int>.generate(numParts, (i) {
      final v = partBd.getInt32(o + 4 * i, Endian.little);
      return v;
    });
    o += 4 * numParts;
    final points = <LatLng>[];
    for (var i = 0; i < numPoints; i++) {
      final x = partBd.getFloat64(o, Endian.little);
      o += 8;
      final y = partBd.getFloat64(o, Endian.little);
      o += 8;
      points.add(LatLng(y, x));
    }
    if (isPolygon) {
      return _fromPolygonRings(
        points,
        parts,
        filename,
        index,
        numParts,
      );
    }
    return _fromPolylineParts(
      points,
      parts,
      filename,
      index,
    );
  }

  static List<BoundaryPolygon> _fromPolylineParts(
    List<LatLng> all,
    List<int> parts,
    String filename,
    int featureIndex,
  ) {
    final out = <BoundaryPolygon>[];
    for (var p = 0; p < parts.length; p++) {
      final a = parts[p];
      final b = p + 1 < parts.length ? parts[p + 1] : all.length;
      if (a >= all.length) continue;
      if (b - a < 2) continue;
      final seg = all.sublist(a, b);
      out.add(
        BoundaryPolygon(
          name: 'SHP L${featureIndex + 1}_$p',
          points: seg,
          sourceFile: filename,
          description: 'Shapefile polyline: $filename',
          zoneType: ZoneType.base,
        ),
      );
    }
    return out;
  }

  static List<BoundaryPolygon> _fromPolygonRings(
    List<LatLng> all,
    List<int> parts,
    String filename,
    int featureIndex,
    int numParts,
  ) {
    if (numParts < 1) return const [];
    final out = <BoundaryPolygon>[];
    for (var p = 0; p < numParts; p++) {
      if (p > 0) break;
      final a = parts[0];
      final b = numParts > 1 ? parts[1] : all.length;
      if (b - a < 3) return const [];
      var ring = all.sublist(a, b);
      if (ring.isNotEmpty &&
          (ring.first.latitude - ring.last.latitude).abs() < 1e-12 &&
          (ring.first.longitude - ring.last.longitude).abs() < 1e-12) {
        ring = ring.sublist(0, ring.length - 1);
      }
      if (ring.length < 3) return const [];
      out.add(
        BoundaryPolygon(
          name: 'SHP P${featureIndex + 1}',
          points: ring,
          sourceFile: filename,
          description: 'Shapefile polygon: $filename',
          zoneType: ZoneType.workArea,
        ),
      );
    }
    return out;
  }
}
