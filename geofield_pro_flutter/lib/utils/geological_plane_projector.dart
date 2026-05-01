import 'dart:math' as math;

import 'geo_orientation.dart';

/// Geologik kamera Focus Mode — bitta geometriya manbai.
///
/// Sensor [GeoOrientationResult] va xuddi shu kadrda olingan
/// gravitatsiya [Vec3] (akselerometr) asosida canvas transformlari.
class FocusModeOverlayGeometry {
  const FocusModeOverlayGeometry({
    required this.rollRad,
    required this.pitchOffsetPx,
    required this.strikeRotationRad,
    required this.dipDeg,
    required this.compassRotationRad,
    required this.isStrikeDegenerate,
  });

  /// Sun’iy gorizont: qiyalik bo‘yicha aylantirish.
  final double rollRad;

  /// Gorizont / halqa markazining vertikal siljishi (piksel), Flutter Y: pastga.
  final double pitchOffsetPx;

  /// Qatlam yo‘nalishi: device `x` o‘ng, `y` ekranga yuqori → Flutter `atan2(-sy, sx)`.
  final double strikeRotationRad;

  final double dipDeg;

  /// Haqiqiy shimol halqada: `-azimut` (soat yo‘nalishida, radian).
  final double compassRotationRad;

  /// Telefon deyarlik gorizontal (`g ∥ ±Z`) — strike yo‘nalishi [fallbackStrikeDeg] dan.
  final bool isStrikeDegenerate;
}

const double _kPitchPixelsPerDegree = 4.5;

/// Plan bo‘yicha: magik koeffitsientlar bitta nomli konstanta; keyinroq `tan(pitch)` ga
/// o‘tkazish mumkin.
FocusModeOverlayGeometry computeFocusModeGeometry({
  required GeoOrientationResult orientation,
  Vec3? gravity,
  double pitchPixelsPerDegree = _kPitchPixelsPerDegree,
}) {
  final rollRad = orientation.roll * math.pi / 180.0;
  final pitchOffsetPx = -orientation.pitch * pitchPixelsPerDegree;

  final azimuthRad = orientation.azimuth * math.pi / 180.0;
  final compassRotationRad = -azimuthRad;

  var strikeRotationRad = orientation.strike * math.pi / 180.0;
  var degenerate = true;

  if (gravity != null) {
    final g = gravity.normalized();
    final sv = g.cross(const Vec3(0, 0, 1));
    if (sv.norm >= 1e-6) {
      final s = sv.normalized();
      strikeRotationRad = math.atan2(-s.y, s.x);
      degenerate = false;
    }
  }

  return FocusModeOverlayGeometry(
    rollRad: rollRad,
    pitchOffsetPx: pitchOffsetPx,
    strikeRotationRad: strikeRotationRad,
    dipDeg: orientation.dip,
    compassRotationRad: compassRotationRad,
    isStrikeDegenerate: degenerate,
  );
}
