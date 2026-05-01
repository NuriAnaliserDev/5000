import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';
import '../../models/geological_line.dart';

/// Chegara poligoni — [GlobalMapScreen] xarita qatlami.
Polygon mapPolygonForBoundary(
  BoundaryPolygon b,
  dynamic currentPos,
  double gisLayerOpacity,
) {
  final isActive =
      currentPos != null && b.containsPoint(LatLng(currentPos.latitude, currentPos.longitude));
  final fillAlpha = isActive ? 0.32 : math.max(0.18, 0.38 * gisLayerOpacity);
  return Polygon(
    points: b.points,
    color: isActive
        ? Colors.green.withValues(alpha: fillAlpha)
        : Colors.blue.withValues(alpha: fillAlpha),
    borderColor: isActive
        ? Colors.greenAccent
        : Colors.cyanAccent.withValues(alpha: math.max(0.75, gisLayerOpacity)),
    borderStrokeWidth: isActive ? 3.0 : 2.5,
  );
}

Polygon mapPolygonForGeologicalLine(GeologicalLine l) {
  final color = l.colorHex != null
      ? Color(int.parse(l.colorHex!, radix: 16) + 0xFF000000)
      : Color(int.parse(GeologicalLine.defaultColorHex(l.lineType), radix: 16) + 0xFF000000);
  return Polygon(
    points: List.generate(l.lats.length, (i) => LatLng(l.lats[i], l.lngs[i])),
    color: color.withValues(alpha: 0.4),
    borderColor: color,
    borderStrokeWidth: l.strokeWidth,
  );
}

/// Vertex tahririda nuqtalar.
List<Polyline> mapVertexEditPolylines(
  List<BoundaryPolygon> boundaries, {
  required String? editingPolygonId,
  required int? selectedVertexIndex,
}) {
  if (editingPolygonId == null) return [];
  final poly = boundaries.firstWhere((b) => b.id == editingPolygonId);
  return poly.points.asMap().entries.map((entry) {
    final isSelected = selectedVertexIndex == entry.key;
    return Polyline(
      points: [entry.value, entry.value],
      color: isSelected ? Colors.red : Colors.yellow,
      strokeWidth: isSelected ? 12 : 8,
      strokeCap: StrokeCap.round,
    );
  }).toList();
}
