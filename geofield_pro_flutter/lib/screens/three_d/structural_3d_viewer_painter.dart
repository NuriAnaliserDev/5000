import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/station.dart';
import '../../utils/three_d_math_utils.dart';

/// To‘liq 3D ko‘rinish (fon gradienti, tor ko‘zgusi, o‘qlar) — faqat [ThreeDViewerScreen].
class Structural3DViewerPainter extends CustomPainter {
  final List<Station> stations;
  final LatLng center;
  final double centerAlt;
  final double rotX;
  final double rotY;
  final double zoom;

  Structural3DViewerPainter({
    required this.stations,
    required this.center,
    required this.centerAlt,
    required this.rotX,
    required this.rotY,
    required this.zoom,
  });

  static const double _worldScale = 0.00015;

  Offset3D _w(Offset3D p) =>
      Offset3D(p.x * _worldScale, p.y * _worldScale, p.z * _worldScale);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final grad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2A3444), Color(0xFF0D1117)],
    );
    canvas.drawRect(r, Paint()..shader = grad.createShader(r));

    final Matrix4 viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..setTranslationRaw(0.0, 0.0, -2.2)
      ..rotateX(rotX * 0.9)
      ..rotateY(rotY * 0.9)
      ..scaleByDouble(zoom, zoom, 1.0, 1.0);

    for (var s in stations) {
      final localPos = ThreeDMathUtils.projectToLocal(
        LatLng(s.lat, s.lng),
        s.altitude,
        center,
        centerAlt,
      );
      final scaledCenter = _w(localPos);
      final screenPos =
          ThreeDMathUtils.projectToScreen(scaledCenter, viewMatrix, size);

      final planePoints =
          ThreeDMathUtils.getStrikeDipPlane(localPos, s.strike, s.dip, 40.0);
      final screenPlanePoints = planePoints
          .map((p) => ThreeDMathUtils.projectToScreen(_w(p), viewMatrix, size))
          .toList();
      final okPlane =
          screenPlanePoints.where((p) => p != Offset.zero).length >= 3;
      if (okPlane) {
        final path = ui.Path()..addPolygon(screenPlanePoints, true);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color =
                Colors.orange.withValues(alpha: 0.35 + (s.dip / 180) * 0.3),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFB74D).withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else if (screenPos != Offset.zero) {
        _drawDipSymbol(canvas, screenPos, s.dip, s.strike);
      }

      if (screenPos != Offset.zero) {
        canvas.drawCircle(screenPos, 6, Paint()..color = Colors.white);
        canvas.drawCircle(
          screenPos,
          6,
          Paint()
            ..color = const Color(0xFF29B6F6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: s.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                      offset: Offset(0.5, 0.5),
                      blurRadius: 2,
                      color: Colors.black),
                ]),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);
        tp.paint(canvas, screenPos + const Offset(8, -10));
      }
    }

    _drawGridFloor(canvas, size, viewMatrix);
    _drawAxisCross(canvas, size, viewMatrix);
  }

  void _drawDipSymbol(Canvas canvas, Offset c, double dip, double strike) {
    final rad = strike * math.pi / 180;
    final dx = 14 * math.sin(rad);
    final dy = -14 * math.cos(rad);
    canvas.drawLine(
      c - Offset(dx, dy) * 0.4,
      c + Offset(dx, dy) * 0.4,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 1.5,
    );
    final tp = TextPainter(
      text: TextSpan(
          text: '${dip.toStringAsFixed(0)}°',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 7)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + const Offset(6, 0));
  }

  void _drawGridFloor(Canvas canvas, Size size, Matrix4 viewMatrix) {
    final paint = Paint()
      ..color = const Color(0xFF6B7A8E).withValues(alpha: 0.5)
      ..strokeWidth = 1.1;
    const double stepM = 80.0;
    const int count = 8;
    for (int i = -count; i <= count; i++) {
      final p1 = _w(Offset3D(i * stepM, -count * stepM, 0));
      final p2 = _w(Offset3D(i * stepM, count * stepM, 0));
      final s1 = ThreeDMathUtils.projectToScreen(p1, viewMatrix, size);
      final s2 = ThreeDMathUtils.projectToScreen(p2, viewMatrix, size);
      if (s1 != Offset.zero && s2 != Offset.zero) {
        canvas.drawLine(s1, s2, paint);
      }
      final p3 = _w(Offset3D(-count * stepM, i * stepM, 0));
      final p4 = _w(Offset3D(count * stepM, i * stepM, 0));
      final a = ThreeDMathUtils.projectToScreen(p3, viewMatrix, size);
      final b = ThreeDMathUtils.projectToScreen(p4, viewMatrix, size);
      if (a != Offset.zero && b != Offset.zero) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  void _drawAxisCross(Canvas canvas, Size size, Matrix4 viewMatrix) {
    final o = _w(Offset3D(0, 0, 0));
    const ax = 0.4;
    final ox = ThreeDMathUtils.projectToScreen(o, viewMatrix, size);
    if (ox == Offset.zero) return;
    final ex = ThreeDMathUtils.projectToScreen(
        _w(Offset3D(ax, 0, 0)), viewMatrix, size);
    final ey = ThreeDMathUtils.projectToScreen(
        _w(Offset3D(0, ax, 0)), viewMatrix, size);
    if (ex != Offset.zero) {
      canvas.drawLine(
          ox,
          ex,
          Paint()
            ..color = Colors.redAccent
            ..strokeWidth = 1.2);
    }
    if (ey != Offset.zero) {
      canvas.drawLine(
          ox,
          ey,
          Paint()
            ..color = Colors.lightGreen
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant Structural3DViewerPainter oldDelegate) {
    return oldDelegate.stations != stations ||
        oldDelegate.center != center ||
        oldDelegate.centerAlt != centerAlt ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.zoom != zoom;
  }
}
