import 'dart:convert';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';

/// KML/GeoJSON/DXF matnini UTF-8 yoki BOM bilan dekodlash.
String decodeBoundaryImportText(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3));
  }
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } catch (_) {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

/// WGS-84 tekshiruvi: lat/lng almashgan bo‘lsa tuzatiladi.
BoundaryPolygon? normalizeBoundaryPolygonIfNeeded(BoundaryPolygon polygon) {
  final pts = polygon.points;
  if (pts.isEmpty) return polygon;

  var hasInvalidLat = false;
  var hasInvalidLng = false;
  for (final p in pts) {
    if (p.latitude.abs() > 90) hasInvalidLat = true;
    if (p.longitude.abs() > 180) hasInvalidLng = true;
  }

  if (!hasInvalidLat && !hasInvalidLng) return polygon;

  final swapped = pts.map((p) => LatLng(p.longitude, p.latitude)).toList();
  var swappedValid = true;
  for (final p in swapped) {
    if (p.latitude.abs() > 90 || p.longitude.abs() > 180) {
      swappedValid = false;
      break;
    }
  }
  if (!swappedValid) return null;

  return BoundaryPolygon(
    name: polygon.name,
    points: swapped,
    sourceFile: polygon.sourceFile,
    description: polygon.description,
    zoneType: polygon.zoneType,
    firestoreId: polygon.firestoreId,
    localId: polygon.localId,
  );
}
