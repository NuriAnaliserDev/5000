import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../utils/three_d_math_utils.dart';

class Structural3DPainter extends CustomPainter {
  final List<Station> stations;
  final LatLng center;
  final double centerAlt;
  final double rotX;
  final double rotY;
  final double zoom;
  final Color planeColor;
  final Color pointColor;

  Structural3DPainter({
    required this.stations,
    required this.center,
    required this.centerAlt,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    this.planeColor = const Color(0xFFFF9800),
    this.pointColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stations.isEmpty) return;

    final Matrix4 viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..setTranslationRaw(0.0, 0.0, -800.0)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..scaleByDouble(zoom, zoom, zoom, 1.0);

    final paintPoint = Paint()..color = pointColor;
    final paintPlane = Paint()..style = PaintingStyle.fill;
    final paintLine = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    for (var s in stations) {
      final localPos = ThreeDMathUtils.projectToLocal(LatLng(s.lat, s.lng), s.altitude, center, centerAlt);
      final screenPos = ThreeDMathUtils.projectToScreen(localPos, viewMatrix, size);

      if (screenPos == Offset.zero) continue;

      // Draw Strike/Dip Plane
      final planePoints = ThreeDMathUtils.getStrikeDipPlane(localPos, s.strike, s.dip, 50.0);
      final screenPlanePoints = planePoints.map((p) => ThreeDMathUtils.projectToScreen(p, viewMatrix, size)).toList();

      if (screenPlanePoints.every((p) => p != Offset.zero)) {
        final path = ui.Path()..addPolygon(screenPlanePoints, true);
        canvas.drawPath(path, paintPlane..color = planeColor.withValues(alpha: 0.25));
        canvas.drawPath(path, paintLine..color = planeColor.withValues(alpha: 0.5));
      }

      // Draw point
      canvas.drawCircle(screenPos, 3, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant Structural3DPainter oldDelegate) =>
      oldDelegate.rotX != rotX ||
      oldDelegate.rotY != rotY ||
      oldDelegate.zoom != zoom ||
      oldDelegate.stations.length != stations.length;
}
