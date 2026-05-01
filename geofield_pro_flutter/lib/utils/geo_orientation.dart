import 'dart:math';

import 'wmm/wmm_model.dart';

class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get norm => sqrt(x * x + y * y + z * z);
  Vec3 normalized() {
    final n = norm;
    if (n < 1e-10) return const Vec3(0, 0, 1); // avoid zero-vector
    return Vec3(x / n, y / n, z / n);
  }

  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);
  Vec3 operator /(double k) => Vec3(x / k, y / k, z / k);
}

class GeoOrientationResult {
  /// Telefon `+Y` ning gorizontal proyeksiyasi (magnit shimoldan soat bo‘yicha),
  /// [declination] qo‘shilgach **true north** (0–360°).
  final double azimuth;

  /// Gorizontdan past qatlam burchagi (0–90°).
  final double dip;

  /// O‘ng qo‘l qoidasi bo‘yicha chasbar, true north ga nisbatan (0–360°).
  final double strike;

  /// Qo‘llanilgan magnit deklinatsiya (WMM yoki qo‘lda).
  final double declination;

  /// Sun’iy gorizont: old-orqa qiyalik (–90…90).
  final double pitch;

  /// Sun’iy gorizont: yon tomonga qiyalik (–180…180).
  final double roll;

  GeoOrientationResult({
    required this.azimuth,
    required this.dip,
    required this.strike,
    required this.declination,
    required this.pitch,
    required this.roll,
  });
}

/// Calculates accurate geological orientation.
///
/// Focus Mode stereonet/strike HUD: natija odatda HUD ga to‘g‘ridan-to‘g‘ri beriladi;
/// `azimuth` va `strike` allaqachon true north — stereonetda `declination` ni ikki marta
/// qo‘llamaslik kerak.
///
/// Android sensor coordinate system:
///   X – points RIGHT along the screen
///   Y – points UP along the screen
///   Z – points OUT OF the screen (toward the user)
///
/// 'gravity'  ← accelerometer reading (points UP opposite to gravity when still,
///               but by convention we treat the raw accel which for a flat phone ≈ (0,0,9.81))
/// 'magnetic' ← magnetometer reading in the same device frame
GeoOrientationResult calculateGeologicalOrientation({
  required Vec3 gravity,
  required Vec3 magnetic,
  double lat = 0,
  double lng = 0,
  double? manualDeclination,
}) {
  // ── 1. Normalise input vectors ──────────────────────────────────────────────
  final g = gravity.normalized();   // gravity direction (down)
  final m = magnetic.normalized();  // raw magnetic field

  // ── 2. Project magnetic onto the horizontal plane (perpendicular to g) ──────
  //   mH = m – (m·g)·g
  //   This removes the vertical component so mH always has a well-defined
  //   horizontal direction even when the phone is lying flat.
  final mHraw = m - g * m.dot(g);
  final mH = mHraw.norm < 1e-6
      ? const Vec3(0, 1, 0) // fallback: assume pointing North
      : mHraw.normalized();

  // ── 3. World-frame axes ─────────────────────────────────────────────────────
  //   North  = mH  (horizontal magnetic North)
  //   East   = g × mH  (right-handed, pointing East)
  //   Down   = g
  final north = mH;
  final east  = g.cross(mH).normalized();  // g × mH is always valid now

  // ── 4. Dip ─────────────────────────────────────────────────────────────────
  //   The geological plane is the phone screen face.
  //   Its outward normal in device coords is +Z = (0,0,1).
  //   Dip = angle between +Z and the horizontal plane = arcsin(|g·Z|)
  //   •  Phone flat face-up  : g ≈ (0,0, 1) → g·Z = 1 → dip = 90° (plane vertical) ← WRONG convention
  //
  //   Geological convention: dip is the angle of the plane below horizontal.
  //   When the screen is flat, the plane IS horizontal → dip = 0°.
  //   When the screen is vertical, the plane is vertical → dip = 90°.
  //
  //   So:  dip = arccos(|g · screenNormal|)  where screenNormal = (0,0,1)
  //        = arccos(|g.z|)
  //   NOTE: we keep abs() so face-up/face-down both give correct dip.
  //   The DIRECTION (face-up vs face-down) is encoded in strike, not dip.
  final double dipRad = acos(g.z.abs().clamp(0.0, 1.0));
  final double dip = (dipRad * 180 / pi).clamp(0.0, 90.0);

  // ── 5. Azimuth (compass heading of the phone's top, +Y axis) ───────────────
  const phoneTop = Vec3(0, 1, 0);
  // Project +Y onto the horizontal plane
  final topHraw = phoneTop - g * phoneTop.dot(g);
  final topH = topHraw.norm < 1e-6
      ? north
      : topHraw.normalized();

  // atan2(E, N) → clockwise from North = azimuth
  var azimuth = atan2(topH.dot(east), topH.dot(north)) * 180 / pi;
  if (azimuth < 0) azimuth += 360;

  // ── 6. Strike ──────────────────────────────────────────────────────────────
  //   Strike is the horizontal line on the geological plane (intersection of
  //   the plane with the horizontal surface).
  //   The plane's normal in device coords = ±(0,0,1).
  //   Strike direction in device coords = g × (0,0,1)   [horizontal & in-plane]
  var strikeVecDevice = g.cross(const Vec3(0, 0, 1));
  if (strikeVecDevice.norm < 1e-4) {
    // Plane is nearly horizontal → strike undefined; default to North
    strikeVecDevice = north;
  } else {
    strikeVecDevice = strikeVecDevice.normalized();
  }

  // Project into world frame
  final sX = strikeVecDevice.dot(east);
  final sY = strikeVecDevice.dot(north);
  var strike = atan2(sX, sY) * 180 / pi;
  if (strike < 0) strike += 360;

  // ── 7. Pitch & Roll (for artificial horizon display) ───────────────────────
  //   Standard aviation / level-indicator convention:
  //     pitch = tilt front-to-back  (positive = front up)
  //     roll  = tilt side-to-side   (positive = right side down)
  //
  //   With gravity already normalised:
  //     pitch = arctan2(–g.y, sqrt(g.x²+g.z²))   ← phone tilting toward user
  //     roll  = arctan2( g.x, g.z)                ← phone rolling right
  //
  //   When phone is flat (g=(0,0,1)): pitch=0, roll=0 ✓
  //   When phone is face toward user (g=(0,–1,0)): pitch=90, roll=0 ✓
  final double pitch = atan2(-g.y, sqrt(g.x * g.x + g.z * g.z)) * 180 / pi;
  final double roll  = atan2(g.x, g.z) * 180 / pi;

  // ── 8. Apply magnetic declination ──────────────────────────────────────────
  final declination = manualDeclination ?? _estimateDeclination(lat, lng);

  return GeoOrientationResult(
    azimuth: (azimuth + declination) % 360,
    dip: dip,
    strike: (strike + declination) % 360,
    declination: declination,
    pitch: pitch,
    roll: roll,
  );
}

/// WMM2025 sferik garmonik modelidan magnit deklinatsiyasini hisoblaydi.
///
/// Oldin qo'llanilgan 60 nuqtali "yolg'on WMM" lookup table olib tashlandi
/// (±3-5° xato bergan). Endi haqiqiy 12-darajali Gauss-Legendre seriyasi
/// ishlatiladi (±0.5° aniqlik, QField/FieldMove darajasi).
///
/// [WmmModel.embedded()] lazy sifatida bir marta yaratiladi va keyin
/// qayta ishlatiladi — har chaqiriqda 12² ta ustun qayta hisoblanmasligi
/// uchun cache qilingan.
WmmModel? _wmmModel;

double _estimateDeclination(double lat, double lng) {
  _wmmModel ??= WmmModel.embedded();
  return _wmmModel!.declination(lat: lat, lng: lng);
}

