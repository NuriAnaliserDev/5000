import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/utils/geo/stereonet_engine.dart';

void main() {
  group('StereonetEngine.projectPole', () {
    test('tik qatlam (dip=90) — chekkada proyeksiya qilinadi', () {
      final p = StereonetEngine.projectPole(
        dipDirection: 0,
        dip: 90,
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      final r = math.sqrt(p.x * p.x + p.y * p.y);
      expect(r, inInclusiveRange(95, 105));
    });

    test('gorizontal qatlam (dip=0) — markazga yaqin', () {
      final p = StereonetEngine.projectPole(
        dipDirection: 45,
        dip: 0,
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      final r = math.sqrt(p.x * p.x + p.y * p.y);
      expect(r, lessThan(1e-6));
    });

    test('Schmidt va Wulff farq qiladi (tik bo‘lmagan dip)', () {
      final s = StereonetEngine.projectPole(
        dipDirection: 90,
        dip: 45,
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      final w = StereonetEngine.projectPole(
        dipDirection: 90,
        dip: 45,
        radius: 100,
        proj: StereonetProjection.wulff,
      );
      final rs = math.sqrt(s.x * s.x + s.y * s.y);
      final rw = math.sqrt(w.x * w.x + w.y * w.y);
      expect((rs - rw).abs(), greaterThan(0.5));
    });
  });

  group('StereonetEngine.meanPoleProjected', () {
    test('bir xil yo‘nalish — o‘z polusini beradi', () {
      final result = StereonetEngine.meanPoleProjected(
        poles: const [
          (dipDir: 90, dip: 30),
          (dipDir: 90, dip: 30),
          (dipDir: 90, dip: 30),
        ],
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      expect(result, isNotNull);
      expect(result!.stats.meanDipDir, closeTo(90, 0.5));
      expect(result.stats.meanDip, closeTo(30, 0.5));
    });

    test('bo‘sh ro‘yxat — null', () {
      final result = StereonetEngine.meanPoleProjected(
        poles: const [],
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      expect(result, isNull);
    });
  });

  group('StereonetEngine.calculateDensityGrid', () {
    test('bo‘sh ro‘yxat — barcha hujayralar 0', () {
      final grid = StereonetEngine.calculateDensityGrid([], 100, 10, 5);
      var sum = 0.0;
      for (final row in grid) {
        for (final v in row) {
          sum += v;
        }
      }
      expect(sum, 0);
    });

    test('markazdagi nuqta — markazga yaqin zichlik eng yuqori', () {
      final points = [ProjectedPoint(x: 0, y: 0)];
      final grid = StereonetEngine.calculateDensityGrid(points, 100, 21, 10);
      final center = grid[10][10];
      final edge = grid[0][10];
      expect(center, greaterThan(edge));
    });
  });

  group('StereonetEngine.alpha95Circle', () {
    test('alpha95=0 yoki 90 — bo‘sh ro‘yxat', () {
      expect(
        StereonetEngine.alpha95Circle(
          meanDipDirection: 90,
          meanDip: 30,
          alpha95Deg: 0,
          radius: 100,
          proj: StereonetProjection.schmidt,
        ),
        isEmpty,
      );
      expect(
        StereonetEngine.alpha95Circle(
          meanDipDirection: 90,
          meanDip: 30,
          alpha95Deg: 95,
          radius: 100,
          proj: StereonetProjection.schmidt,
        ),
        isEmpty,
      );
    });

    test('odatdagi alpha95 — doira (yopiq nuqtalar)', () {
      final pts = StereonetEngine.alpha95Circle(
        meanDipDirection: 90,
        meanDip: 30,
        alpha95Deg: 10,
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      expect(pts.length, greaterThan(10));
      final d = (pts.first - pts.last).distance;
      expect(d, lessThan(1e-3));
    });
  });

  group('StereonetEngine.calculateGreatCircle', () {
    test('vertikal qatlam (dip=90) — ~doira', () {
      final pts = StereonetEngine.calculateGreatCircle(
        strike: 0,
        dip: 90,
        radius: 100,
        proj: StereonetProjection.schmidt,
      );
      expect(pts, isNotEmpty);
    });
  });
}
