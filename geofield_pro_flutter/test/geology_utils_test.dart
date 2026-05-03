import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/utils/geology_utils.dart';
import 'package:geofield_pro_flutter/utils/geo/thickness_calculator.dart';

void main() {
  group('GeologyUtils Tests', () {
    test('UTM conversion for Toshkent', () {
      final utm = GeologyUtils.toUtm(41.2995, 69.2401);
      expect(utm.isValid, isTrue);
      // We expect a valid Easting for standard UTM mappings
      expect(utm.easting, greaterThan(100000));
      expect(utm.easting, lessThan(900000));
    });

    test('apparentDip', () {
      final appDip = GeologyUtils.apparentDip(
        trueDip: 30.0,
        dipDirection: 90.0,
        sectionAzimuth: 45.0,
      );
      expect(appDip, closeTo(22.2, 0.5));
    });

    test('fisherStatsAxial - identical angles', () {
      final angles = [170.0, 170.0, 170.0];
      final stats = GeologyUtils.fisherStatsAxial(angles);
      expect(stats.meanAngle, closeTo(170.0, 0.1));
      expect(stats.kappa, equals(0.0));
    });

    test('fisherStatsAxial - opposite angles', () {
      final angles = [10.0, 190.0, 10.0, 190.0];
      final stats = GeologyUtils.fisherStatsAxial(angles);
      expect(stats.meanAngle, anyOf(closeTo(10.0, 0.1), closeTo(190.0, 0.1)));
    });

    test('trueThickness (perpendicular)', () {
      final thickness = ThicknessCalculator.perpendicular(
        outcropWidth: 10.0,
        trueDip: 30.0,
      );
      expect(thickness, closeTo(5.0, 0.1));
    });
  });
}
