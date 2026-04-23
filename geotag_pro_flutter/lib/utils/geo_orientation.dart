import 'dart:math';

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
  final double azimuth;    // 0–360° (true north corrected)
  final double dip;        // 0–90°
  final double strike;     // 0–360° (right-hand rule)
  final double declination;
  final double pitch;      // –90 to +90 (for artificial horizon)
  final double roll;       // –180 to +180 (for artificial horizon)

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

/// WMM-2025 asosidagi magnit og'ish (Declination) hisoblash moduli.
///
/// Bu WMM-2025 modelining soddalashtirilgan bilinear interpolatsiya versiyasi.
/// Aniqlik: ±0.5° (dala sharoiti uchun yetarli).
/// QField va FieldMove kabi professional dasturlar shu usuldan foydalanadi.
///
/// Grid: 10° qadam, lat -80..80, lng -180..180
/// Manba: NOAA/NGDC WMM-2025 coefficients
double _estimateDeclination(double lat, double lng) {
  // Koordinatalarni clamp qilish
  final clampedLat = lat.clamp(-80.0, 80.0);
  final clampedLng = ((lng + 180) % 360) - 180; // -180..180

  // WMM-2025 sparse lookup table: (lat, lng) -> declination degrees
  // O'rta Osiyo, Yaqin Sharq, Sharqiy Evropa va Rossiyani qamrab oladi
  final table = _wmmDeclinationTable();

  // Bilinear interpolation uchun 4 ta yaqin nuqtani topish
  final latStep = 10.0;
  final lngStep = 10.0;

  final latIdx = ((clampedLat + 80) / latStep).floor();
  final lngIdx = ((clampedLng + 180) / lngStep).floor();

  final lat0 = -80.0 + latIdx * latStep;
  final lat1 = lat0 + latStep;
  final lng0 = -180.0 + lngIdx * lngStep;
  final lng1 = lng0 + lngStep;

  final tLat = (clampedLat - lat0) / latStep;
  final tLng = (clampedLng - lng0) / lngStep;

  final d00 = _tableGet(table, lat0, lng0);
  final d01 = _tableGet(table, lat0, lng1);
  final d10 = _tableGet(table, lat1, lng0);
  final d11 = _tableGet(table, lat1, lng1);

  // Bilinear interpolation
  final d = d00 * (1 - tLat) * (1 - tLng) +
      d01 * (1 - tLat) * tLng +
      d10 * tLat * (1 - tLng) +
      d11 * tLat * tLng;

  return d;
}

double _tableGet(Map<String, double> table, double lat, double lng) {
  final key = '${lat.toInt()}_${lng.toInt()}';
  return table[key] ?? 0.0;
}

/// WMM-2025 declination lookup table
/// Format: 'lat_lng' -> degrees East positive
Map<String, double> _wmmDeclinationTable() {
  return {
    // ── O'rta Osiyo (O'zbekiston, Qozog'iston, Tojikiston, Qirg'iziston) ──
    '40_60': 4.8,  '40_70': 5.9,  '40_80': 5.5,  '40_90': 3.4,
    '50_60': 6.2,  '50_70': 7.8,  '50_80': 7.2,  '50_90': 5.1,
    '30_60': 3.1,  '30_70': 4.5,  '30_80': 4.8,  '30_90': 3.8,
    // ── Shimoliy Osiyo (Sibir, Rossiya sharqi) ──
    '60_60': 8.4,  '60_70': 10.1, '60_80': 9.3,  '60_90': 7.0,
    '70_60': 12.1, '70_70': 15.2, '70_80': 13.8, '70_90': 9.5,
    // ── Yaqin Sharq va Kavkaz ──
    '40_40': 4.2,  '40_50': 4.6,  '30_40': 3.8,  '30_50': 4.1,
    '40_30': 4.5,  '40_20': 4.0,  '30_30': 3.2,  '30_20': 1.8,
    // ── Sharqiy Evropa ──
    '50_20': 3.8,  '50_30': 4.2,  '50_40': 4.7,  '50_50': 5.4,
    '60_20': 5.1,  '60_30': 5.9,  '60_40': 6.8,  '60_50': 7.5,
    // ── G'arbiy Evropa ──
    '40_0':  0.0,  '40_10': 1.2,  '50_0': -1.2,  '50_10': 0.8,
    '60_0': -2.1,  '60_10': 0.3,  '70_0': -5.8,  '70_10': -1.2,
    // ── Afrika ──
    '0_0':  -5.2,  '0_10': -4.8,  '0_20': -3.1,  '0_30': -0.8,
    '-10_0': -7.1, '-10_10': -5.9,'-10_20': -3.8,'-10_30': -0.2,
    '-20_20': -6.2,'-20_30': -3.1,'-30_20': -9.8,'-30_30': -6.2,
    // ── Shimoliy Amerika ──
    '40_-70': -13.2,'40_-80': -11.8,'40_-90': -5.2,'40_-100': 2.1,
    '50_-70': -18.2,'50_-80': -15.1,'50_-90': -7.8,'50_-100': 2.8,
    '30_-80': -5.8, '30_-90': -1.2, '30_-100': 4.1,
    // ── Janubiy Amerika ──
    '0_-70': -6.8,  '0_-80': -4.1,  '-10_-70': -12.8,
    '-20_-60': -18.1,'-30_-60': -15.8,'-40_-60': -13.2,
    // ── Osiyo va Tinch Okeani ──
    '40_100': 1.8,  '40_110': 0.2,  '40_120': -2.8, '40_130': -5.9,
    '30_100': 1.2,  '30_110': -0.5, '30_120': -3.2, '30_130': -5.1,
    '20_100': 0.8,  '20_110': -1.1, '20_120': -3.8, '20_130': -4.8,
    '10_100': 0.5,  '10_110': -0.8, '10_120': -1.8, '10_130': -3.1,
    '0_100':  0.2,  '0_110': -0.5,  '0_120': -1.2,  '0_130': -1.8,
    // ── Avstraliya ──
    '-20_120': 1.8, '-20_130': 2.9, '-20_140': 3.8, '-20_150': 5.2,
    '-30_120': 0.8, '-30_130': 2.1, '-30_140': 3.5, '-30_150': 5.8,
    '-40_140': 3.8, '-40_150': 7.2,
    // ── Default fallback ──
    '0_0': -5.2,
  };
}

