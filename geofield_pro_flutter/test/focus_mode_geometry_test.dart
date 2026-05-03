import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/utils/geo_orientation.dart';
import 'package:geofield_pro_flutter/utils/geological_plane_projector.dart';

GeoOrientationResult _o({
  required double strike,
  required double dip,
  double azimuth = 0,
  double pitch = 0,
  double roll = 0,
}) {
  return GeoOrientationResult(
    azimuth: azimuth,
    dip: dip,
    strike: strike,
    declination: 0,
    pitch: pitch,
    roll: roll,
  );
}

void main() {
  group('computeFocusModeGeometry', () {
    test('gorizontal telefon: strike degenerate, geografik strike ishlatiladi',
        () {
      final g = Vec3(0, 0, 9.81);
      final geo = _o(strike: 45, dip: 0, azimuth: 10, pitch: 0, roll: 0);
      final m = computeFocusModeGeometry(orientation: geo, gravity: g);
      expect(m.isStrikeDegenerate, isTrue);
      expect(m.strikeRotationRad, closeTo(45 * math.pi / 180, 1e-9));
      expect(m.compassRotationRad, closeTo(-10 * math.pi / 180, 1e-9));
    });

    test('vertikalcha: strike vektoridan burchak (degenerate emas)', () {
      // g asosan -Y (yuqoriga ko‘rsatilgan akselerometr konventsiyasi bilan mos)
      final g = Vec3(0, -9.81, 0);
      final geo = _o(strike: 999, dip: 45, azimuth: 0, pitch: 45, roll: 0);
      final m = computeFocusModeGeometry(orientation: geo, gravity: g);
      expect(m.isStrikeDegenerate, isFalse);
      // g×k ≈ (-1,0,0) → π yoki -π (ekvivalent yo‘nalish).
      expect(
        (m.strikeRotationRad - math.pi).abs() < 1e-6 ||
            (m.strikeRotationRad + math.pi).abs() < 1e-6,
        isTrue,
      );
    });

    test('shimol halqasi: azimut 90° → compassRotation -π/2', () {
      final geo = _o(strike: 0, dip: 30, azimuth: 90, pitch: 0, roll: 0);
      final m = computeFocusModeGeometry(
        orientation: geo,
        gravity: Vec3(0, 0, 9.81),
      );
      expect(m.compassRotationRad, closeTo(-math.pi / 2, 1e-9));
    });

    test('pitch offset: linear -orientation.pitch * scale', () {
      final geo = _o(strike: 0, dip: 0, pitch: -6, roll: 0);
      final m = computeFocusModeGeometry(
        orientation: geo,
        gravity: Vec3(0, 0, 1),
        pitchPixelsPerDegree: 4.5,
      );
      expect(m.pitchOffsetPx, 27.0);
    });
  });
}
