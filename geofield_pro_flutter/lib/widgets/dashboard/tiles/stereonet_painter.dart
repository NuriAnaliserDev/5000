import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../utils/geology_utils.dart';
import '../../../models/station.dart';

class StereonetPainter extends CustomPainter {
  final List<Station> stations;
  final Map<String, Color> typeColor;
  final bool isDark;
  final StereonetProjection projection;
  final bool showContours;

  /// Ixtiyoriy: [compute]da hisoblangan zichlik (UI threadni tushirmaslik).
  final List<List<double>>? densityGrid;
  final bool showGreatCircles;
  final bool showMeanVector;

  StereonetPainter({
    required this.stations,
    required this.typeColor,
    required this.isDark,
    required this.projection,
    required this.showContours,
    this.densityGrid,
    this.showGreatCircles = false,
    this.showMeanVector = false,
  });

  Color _getHeatColor(double fraction) {
    if (fraction < 0.2) return Colors.blue.withValues(alpha: fraction * 2);
    if (fraction < 0.5) return Colors.green.withValues(alpha: fraction * 1.5);
    if (fraction < 0.8) return Colors.orange.withValues(alpha: fraction);
    return Colors.red.withValues(alpha: fraction);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 12;

    // Background
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color =
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
    );

    // Extract all points (Primary + Measurements)
    final points = <ProjectedPoint>[];
    final poles = <({double dipDir, double dip})>[];

    for (final s in stations) {
      final dipDir = s.dipDirection ?? ((s.strike + 90) % 360);
      final p1 = StereonetEngine.projectPole(
        dipDirection: dipDir,
        dip: s.dip,
        radius: r,
        proj: projection,
        data: s,
      );
      points.add(p1);
      poles.add((dipDir: dipDir, dip: s.dip));

      if (s.measurements != null) {
        for (final m in s.measurements!) {
          points.add(StereonetEngine.projectPole(
            dipDirection: m.dipDirection,
            dip: m.dip,
            radius: r,
            proj: projection,
            data: s,
          ));
          poles.add((dipDir: m.dipDirection, dip: m.dip));
        }
      }
    }

    if (showContours && points.isNotEmpty) {
      const gridSize = 50;
      final bw = r * 0.12;
      final List<List<double>> grid;
      if (densityGrid != null &&
          densityGrid!.length == gridSize &&
          densityGrid!.isNotEmpty &&
          densityGrid![0].length == gridSize) {
        grid = densityGrid!;
      } else {
        grid = StereonetEngine.calculateDensityGrid(points, r, gridSize, bw);
      }

      double maxDensity = 0.0;
      for (var row in grid) {
        for (var v in row) {
          if (v > maxDensity) maxDensity = v;
        }
      }

      if (maxDensity > 0) {
        final cellSize = (r * 2) / gridSize;
        for (int y = 0; y < gridSize; y++) {
          for (int x = 0; x < gridSize; x++) {
            final density = grid[y][x];
            if (density < maxDensity * 0.05) continue;

            final px = cx - r + x * cellSize;
            final py = cy - r + y * cellSize;

            final dfx = px + cellSize / 2 - cx;
            final dfy = py + cellSize / 2 - cy;
            if (dfx * dfx + dfy * dfy > r * r) continue;

            final color = _getHeatColor(density / maxDensity);
            canvas.drawRect(
                Rect.fromLTWH(px, py, cellSize + 0.5, cellSize + 0.5),
                Paint()..color = color);
          }
        }
      }
    }

    // Great Circles
    if (showGreatCircles) {
      final gcPaint = Paint()
        ..color = (isDark ? Colors.white24 : Colors.black12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (final s in stations) {
        final gcPoints = StereonetEngine.calculateGreatCircle(
          strike: s.strike,
          dip: s.dip,
          radius: r,
          proj: projection,
        );
        if (gcPoints.isNotEmpty) {
          final path = Path();
          path.moveTo(cx + gcPoints[0].dx, cy + gcPoints[0].dy);
          for (var p in gcPoints) {
            path.lineTo(cx + p.dx, cy + p.dy);
          }
          canvas.drawPath(path, gcPaint);
        }
      }
    }

    // Outer ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Cross-hair & Concentric Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 0.6;

    // Dip circles (10, 30, 50, 70 degrees)
    for (double dip in [10, 30, 50, 70]) {
      double circleR;
      if (projection == StereonetProjection.wulff) {
        circleR = r * math.tan(((90 - dip) / 2) * math.pi / 180);
      } else {
        circleR = r * math.sqrt(2) * math.sin(((90 - dip) / 2) * math.pi / 180);
      }
      canvas.drawCircle(
          Offset(cx, cy), circleR, gridPaint..style = PaintingStyle.stroke);
    }

    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), gridPaint);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), gridPaint);

    // Azimut chiziqlari: har 5° (oldingi 2° — 180 ta chiziq, UI thread uchun og‘ir edi).
    final tickPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final outerX = cx + r * math.cos(angle);
      final outerY = cy + r * math.sin(angle);
      int tickLen = 2;
      if (i % 10 == 0) tickLen = 5;
      if (i % 90 == 0) tickLen = 10;

      final innerX = cx + (r - tickLen) * math.cos(angle);
      final innerY = cy + (r - tickLen) * math.sin(angle);
      canvas.drawLine(
          Offset(outerX, outerY), Offset(innerX, innerY), tickPaint);
    }

    // Plot Individual Points
    for (final pt in points) {
      final s = pt.data;
      String mType = 'bedding';
      if (s is Station) {
        mType = s.measurementType ?? 'bedding';
      }
      final color = typeColor[mType] ??
          (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2));

      // Glow effect
      canvas.drawCircle(
          Offset(cx + pt.x, cy + pt.y),
          5.0,
          Paint()
            ..color = color.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

      canvas.drawCircle(
          Offset(cx + pt.x, cy + pt.y), 3.5, Paint()..color = color);
      canvas.drawCircle(
          Offset(cx + pt.x, cy + pt.y),
          3.5,
          Paint()
            ..color =
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }

    // Mean Vector & α₉₅ (haqiqiy 3D Fisher — geologik to'g'ri)
    if (showMeanVector && poles.isNotEmpty) {
      final mean = StereonetEngine.meanPoleProjected(
        poles: poles,
        radius: r,
        proj: projection,
      );
      if (mean != null) {
        final mp = mean.projected;
        final stats = mean.stats;

        // Mean Pole yulduzi
        canvas.drawCircle(
          Offset(cx + mp.x, cy + mp.y),
          6,
          Paint()
            ..color = Colors.yellow.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(cx + mp.x, cy + mp.y),
          4,
          Paint()..color = Colors.yellow,
        );

        // α₉₅ konusi — great-circle sifatida mean pole atrofida (haqiqiy)
        if (!stats.alpha95.isNaN && stats.alpha95 < 90) {
          final ring = StereonetEngine.alpha95Circle(
            meanDipDirection: stats.meanDipDir,
            meanDip: stats.meanDip,
            alpha95Deg: stats.alpha95,
            radius: r,
            proj: projection,
          );
          if (ring.isNotEmpty) {
            final path = Path()..moveTo(cx + ring.first.dx, cy + ring.first.dy);
            for (final pt in ring.skip(1)) {
              path.lineTo(cx + pt.dx, cy + pt.dy);
            }
            canvas.drawPath(
              path,
              Paint()
                ..color = Colors.yellow.withValues(alpha: 0.35)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5,
            );
          }
        }
      }
    }

    // Cardinal labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void drawLabel(String text, Offset pos) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.6),
        ),
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    drawLabel('N', Offset(cx, cy - r - 18));
    drawLabel('S', Offset(cx, cy + r + 18));
    drawLabel('E', Offset(cx + r + 18, cy));
    drawLabel('W', Offset(cx - r - 18, cy));
  }

  @override
  bool shouldRepaint(StereonetPainter old) {
    if (old.isDark != isDark ||
        old.projection != projection ||
        old.showContours != showContours ||
        old.densityGrid != densityGrid ||
        old.showGreatCircles != showGreatCircles ||
        old.showMeanVector != showMeanVector) {
      return true;
    }
    if (!mapEquals(old.typeColor, typeColor)) {
      return true;
    }
    if (old.stations.length != stations.length) {
      return true;
    }
    for (int i = 0; i < stations.length; i++) {
      if (old.stations[i].key != stations[i].key) {
        return true;
      }
    }
    return false;
  }
}
