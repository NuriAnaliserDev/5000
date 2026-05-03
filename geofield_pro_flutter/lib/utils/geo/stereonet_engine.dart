import 'dart:math';
import 'dart:ui';

import 'circular_stats.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STEREONET ENGINE (Projections and Contouring)
// ═══════════════════════════════════════════════════════════════════════════

enum StereonetProjection { schmidt, wulff }

class ProjectedPoint {
  final double x;
  final double y;
  final dynamic data;

  ProjectedPoint({required this.x, required this.y, this.data});
}

class StereonetEngine {
  static ProjectedPoint projectPole({
    required double dipDirection,
    required double dip,
    required double radius,
    required StereonetProjection proj,
    dynamic data,
  }) {
    final poleTrend = (dipDirection + 180) % 360;
    final polePlunge = 90 - dip;
    final trendRad = poleTrend * pi / 180.0;

    double rOut;
    if (proj == StereonetProjection.wulff) {
      final pDeg = 90 - polePlunge;
      rOut = radius * tan((pDeg / 2) * pi / 180);
    } else {
      final pDeg = 90 - polePlunge;
      rOut = radius * sqrt(2) * sin((pDeg / 2) * pi / 180);
    }

    final cx = rOut * sin(trendRad);
    final cy = -rOut * cos(trendRad);

    return ProjectedPoint(x: cx, y: cy, data: data);
  }

  static ({ProjectedPoint projected, FisherStats3D stats})? meanPoleProjected({
    required List<({double dipDir, double dip})> poles,
    required double radius,
    required StereonetProjection proj,
  }) {
    if (poles.isEmpty) return null;
    final stats = CircularStats.fisher3D(poles);
    if (stats.meanDip.isNaN || stats.meanDipDir.isNaN) return null;
    final projected = projectPole(
      dipDirection: stats.meanDipDir,
      dip: stats.meanDip,
      radius: radius,
      proj: proj,
    );
    return (projected: projected, stats: stats);
  }

  static List<Offset> alpha95Circle({
    required double meanDipDirection,
    required double meanDip,
    required double alpha95Deg,
    required double radius,
    required StereonetProjection proj,
  }) {
    if (alpha95Deg.isNaN || alpha95Deg <= 0 || alpha95Deg >= 90)
      return const [];
    final trendRad = ((meanDipDirection + 180) % 360) * pi / 180.0;
    final plungeRad = (90 - meanDip) * pi / 180.0;
    final cosPl = cos(plungeRad);
    final vx = cosPl * sin(trendRad);
    final vy = cosPl * cos(trendRad);
    final vz = sin(plungeRad);

    // v bilan gorizontal bo‘lmagan yordam vektori (gram–Schmidt uchun)
    final double hx;
    final double hy;
    final double hz;
    if (vz.abs() < 0.9) {
      hx = 0.0;
      hy = 0.0;
      hz = 1.0;
    } else {
      hx = 1.0;
      hy = 0.0;
      hz = 0.0;
    }
    var ex = hy * vz - hz * vy;
    var ey = hz * vx - hx * vz;
    var ez = hx * vy - hy * vx;
    final eNorm = sqrt(ex * ex + ey * ey + ez * ez);
    ex /= eNorm;
    ey /= eNorm;
    ez /= eNorm;
    final fx = vy * ez - vz * ey;
    final fy = vz * ex - vx * ez;
    final fz = vx * ey - vy * ex;

    final cosA = cos(alpha95Deg * pi / 180.0);
    final sinA = sin(alpha95Deg * pi / 180.0);

    final points = <Offset>[];
    for (int i = 0; i <= 72; i++) {
      final phi = i * 5.0 * pi / 180.0;
      final px = vx * cosA + (ex * cos(phi) + fx * sin(phi)) * sinA;
      final py = vy * cosA + (ey * cos(phi) + fy * sin(phi)) * sinA;
      final pz = vz * cosA + (ez * cos(phi) + fz * sin(phi)) * sinA;

      var dx = px, dy = py, dz = pz;
      if (dz < 0) {
        dx = -dx;
        dy = -dy;
        dz = -dz;
      }

      final theta = acos(dz.clamp(-1.0, 1.0));
      double rOut;
      if (proj == StereonetProjection.wulff) {
        rOut = radius * tan(theta / 2);
      } else {
        rOut = radius * sqrt(2) * sin(theta / 2);
      }
      final mag = sqrt(dx * dx + dy * dy);
      if (mag < 1e-9) {
        points.add(Offset.zero);
      } else {
        points.add(Offset(dx / mag * rOut, -dy / mag * rOut));
      }
    }
    return points;
  }

  static List<List<double>> calculateDensityGrid(
    List<ProjectedPoint> points,
    double radius,
    int gridSize,
    double bandwidth,
  ) {
    final grid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
    final cellSize = (radius * 2) / gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final cx = -radius + x * cellSize + cellSize / 2;
        final cy = -radius + y * cellSize + cellSize / 2;
        if (cx * cx + cy * cy > radius * radius) continue;
        var density = 0.0;
        for (final p in points) {
          final distSq = pow(p.x - cx, 2) + pow(p.y - cy, 2);
          density += exp(-distSq / (2 * pow(bandwidth, 2)));
        }
        grid[y][x] = density;
      }
    }
    return grid;
  }

  /// Pole markazida, +X sharq, +Y shimol (Flutter: ekranda yuqori `-dy` bilan mos).
  /// [azimuthDeg] — telefon shimoli (soat bo‘yicha) geologik frame ga aylantirish.
  static Offset rotateStereonetByAzimuth(
    Offset stereonetOffset,
    double azimuthDeg,
  ) {
    final th = azimuthDeg * pi / 180.0;
    final xm = stereonetOffset.dx;
    final ym = -stereonetOffset.dy;
    final xr = xm * cos(th) - ym * sin(th);
    final yr = xm * sin(th) + ym * cos(th);
    return Offset(xr, -yr);
  }

  static List<Offset> calculateGreatCircle({
    required double strike,
    required double dip,
    required double radius,
    required StereonetProjection proj,
  }) {
    final points = <Offset>[];
    final dipDir = (strike + 90) % 360;
    final ddRad = (90 - dipDir) * pi / 180;
    final dipRad = dip.clamp(0.0, 90.0) * pi / 180;
    final sinD = sin(dipRad);

    // 0.5° qadam: yuqori yarim sfera kesishlarida "tirtiq" kamayadi.
    for (int i = -180; i <= 180; i++) {
      final beta = i * 0.5 * pi / 180;
      final xS = cos(beta);
      final yS = sin(beta) * cos(dipRad);
      final zS = -sin(beta) * sinD;
      final xR = xS * cos(ddRad) - yS * sin(ddRad);
      final yR = xS * sin(ddRad) + yS * cos(ddRad);
      if (zS > 0) continue;
      final theta = acos((-zS).clamp(-1.0, 1.0));
      double rOut;
      if (proj == StereonetProjection.wulff) {
        rOut = radius * tan(theta / 2);
      } else {
        rOut = radius * sqrt(2) * sin(theta / 2);
      }
      final mag = sqrt(xR * xR + yR * yR);
      if (mag < 1e-12) {
        points.add(Offset.zero);
        continue;
      }
      var px = xR / mag * rOut;
      var py = -yR / mag * rOut;
      var h = sqrt(px * px + py * py);
      if (h > radius) {
        final s = radius / h;
        px *= s;
        py *= s;
      }
      points.add(Offset(px, py));
    }
    return points;
  }

  /// Geologik chiziq: [trendDeg] — shimoldan soat strelkasi bo‘yicha (0° = N),
  /// [plungeDeg] — gorizontal ostidagi moyil (0° = gorizontal, 90° = tik pastga).
  /// Tik chiziq (plunge=90°) proyeksiya markazida — [Offset.zero] (UI da chiziq yo‘q).
  static Offset projectLineation({
    required double trendDeg,
    required double plungeDeg,
    required double radius,
    required StereonetProjection proj,
  }) {
    final trendRad = trendDeg * pi / 180.0;
    final plungeRad = plungeDeg * pi / 180.0;
    var dx = cos(plungeRad) * sin(trendRad);
    var dy = cos(plungeRad) * cos(trendRad);
    var dz = sin(plungeRad);
    if (dz < 0) {
      dx = -dx;
      dy = -dy;
      dz = -dz;
    }
    final theta = acos(dz.clamp(-1.0, 1.0));
    double rOut;
    if (proj == StereonetProjection.wulff) {
      rOut = radius * tan(theta / 2);
    } else {
      rOut = radius * sqrt(2) * sin(theta / 2);
    }
    final mag = sqrt(dx * dx + dy * dy);
    if (mag < 1e-9) {
      return Offset.zero;
    }
    return Offset(dx / mag * rOut, -dy / mag * rOut);
  }
}
