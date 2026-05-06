import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../services/cross_section_service.dart';

class CrossSectionProfilePainter extends CustomPainter {
  final List<CrossSectionData> data;
  final double exaggeration;
  final double totalLength;
  final ColorScheme colorScheme;

  CrossSectionProfilePainter({
    required this.data,
    required this.exaggeration,
    required this.totalLength,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalLength == 0) return;

    final double padding = 40.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);

    final double horizontalScale = drawWidth / totalLength;

    double minAlt = 0;
    double maxAlt = 100;
    if (data.isNotEmpty) {
      minAlt = data.map((d) => d.station.altitude).reduce(min) - 100;
      maxAlt = data.map((d) => d.station.altitude).reduce(max) + 100;
    }
    final double altRange = max(100, maxAlt - minAlt);

    _drawGrid(canvas, size, padding, drawWidth, drawHeight, minAlt, maxAlt,
        totalLength);

    final surfacePath = ui.Path();
    bool first = true;

    final dipPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var d in data) {
      final double x = padding + (d.distanceAlongProfile * horizontalScale);
      final double y = size.height -
          padding -
          ((d.station.altitude - minAlt) * (drawHeight / altRange));

      if (first) {
        surfacePath.moveTo(x, y);
        first = false;
      } else {
        surfacePath.lineTo(x, y);
      }

      final double angleRad = d.apparentDip * pi / 180.0;
      const double stickLen = 30.0;

      dipPaint.color = _getDipColor(d.apparentDip);

      final dx = stickLen * cos(angleRad);
      final dy = stickLen * sin(angleRad) * exaggeration;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx, y + dy),
        dipPaint,
      );

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);

      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: d.station.name,
            style: const TextStyle(color: Colors.white, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - 15));
    }

    canvas.drawPath(
      surfacePath,
      Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double w, double h,
      double minAlt, double maxAlt, double len) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    for (double d = 0; d <= len; d += len / 5) {
      final double x = padding + (d * (w / len));
      canvas.drawLine(
          Offset(x, padding), Offset(x, size.height - padding), gridPaint);

      _drawText(
          canvas, '${d.toInt()}m', Offset(x - 10, size.height - padding + 5));
    }

    final double range = maxAlt - minAlt;
    for (double a = minAlt; a <= maxAlt; a += range / 5) {
      final double y = size.height - padding - ((a - minAlt) * (h / range));
      canvas.drawLine(
          Offset(padding, y), Offset(size.width - padding, y), gridPaint);

      _drawText(canvas, '${a.toInt()}m', Offset(padding - 35, y - 5));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white38, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  Color _getDipColor(double dip) {
    if (dip > 70) return Colors.redAccent;
    if (dip > 45) return Colors.orangeAccent;
    if (dip > 20) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  @override
  bool shouldRepaint(CrossSectionProfilePainter old) =>
      old.data != data ||
      old.exaggeration != exaggeration ||
      old.totalLength != totalLength;
}
