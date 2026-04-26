import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:geofield_pro_flutter/utils/spatial_calculator.dart';

void main() {
  group('SpatialCalculator.distanceBetween', () {
    test('bir xil nuqta — 0 metr', () {
      final d = SpatialCalculator.distanceBetween(
        const LatLng(41, 69),
        const LatLng(41, 69),
      );
      expect(d, closeTo(0, 1e-3));
    });

    test('ekvator bo‘ylab 1 daraja ≈ 111.32 km', () {
      final d = SpatialCalculator.distanceBetween(
        const LatLng(0, 0),
        const LatLng(0, 1),
      );
      expect(d / 1000, closeTo(111.32, 0.5));
    });

    test('Toshkent ↔ Samarqand ≈ 265..285 km', () {
      final d = SpatialCalculator.distanceBetween(
        const LatLng(41.2995, 69.2401),
        const LatLng(39.6270, 66.9750),
      );
      expect(d / 1000, inInclusiveRange(250.0, 300.0));
    });
  });

  group('SpatialCalculator.calculatePerimeter', () {
    test('3 nuqtali uchburchak — tomonlar yig‘indisi', () {
      final p = SpatialCalculator.calculatePerimeter(const [
        LatLng(0, 0),
        LatLng(0, 1),
        LatLng(1, 0),
      ]);
      expect(p, greaterThan(0));
      expect(p / 1000, greaterThan(300));
    });

    test('2 ta nuqta — 0 (yopiq emas)', () {
      final p = SpatialCalculator.calculatePerimeter(const [
        LatLng(0, 0),
        LatLng(0, 1),
      ]);
      expect(p, 0);
    });
  });

  group('SpatialCalculator.calculateArea', () {
    test('3 nuqtadan kam — 0', () {
      expect(
        SpatialCalculator.calculateArea(const [
          LatLng(0, 0),
          LatLng(0, 1),
        ]),
        0,
      );
    });

    test('1°x1° kvadrat (ekvator atrofida) — sfera maydoni', () {
      final area = SpatialCalculator.calculateArea(const [
        LatLng(0, 0),
        LatLng(1, 0),
        LatLng(1, 1),
        LatLng(0, 1),
      ]);
      // Polar triangle + katta sfera tuzatish — ~12k–25k km² oralig‘ida bo‘lishi mumkin
      expect(area / 1e6, inInclusiveRange(10000.0, 28000.0));
    });
  });
}
