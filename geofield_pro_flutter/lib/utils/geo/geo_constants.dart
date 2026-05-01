/// Geodesy va geografiya hisoblar uchun yagona konstantalar manbai.
///
/// Loyihada ilgari uch xil Earth radius ishlatilgan (6371000, 6378137).
/// Bu fayl — yagona haqiqat manbai. Barcha matematik formulalar shu
/// qiymatlarga bog'lanadi.
///
/// Standart: **WGS84** (GPS, UTM, GeoJSON, KML, Shapefile).
/// Ref: NIMA TR8350.2, 3rd Edition.
library;

class GeoConstants {
  GeoConstants._();

  // ── WGS84 Ellipsoidi ──────────────────────────────────────────────────────
  /// Semi-major axis (katta o'q) — ekvator radiusi. Birlik: metr.
  static const double wgs84A = 6378137.0;

  /// Flattening (yassilik koeffitsiyenti) 1/f.
  static const double wgs84InvF = 298.257223563;

  /// Flattening f = 1/invF.
  static const double wgs84F = 1.0 / wgs84InvF;

  /// Semi-minor axis (kichik o'q) b = a(1-f).
  static const double wgs84B = wgs84A * (1.0 - wgs84F);

  /// First eccentricity squared e² = f(2-f).
  static const double wgs84E2 = wgs84F * (2.0 - wgs84F);

  /// Second eccentricity squared e'² = e²/(1-e²).
  static const double wgs84EPrime2 = wgs84E2 / (1.0 - wgs84E2);

  /// Mean Earth radius (o'rta radius) — 3D tekis proyeksiyalar uchun.
  /// Birlik: metr. Haversine va kichik sohalarda ishlatiladi.
  static const double meanEarthRadius = 6371008.8;

  // ── UTM (Universal Transverse Mercator) ───────────────────────────────────
  /// UTM central meridian scale factor.
  static const double utmK0 = 0.9996;

  /// UTM false easting (central meridianning to'g'ri siljishi).
  static const double utmFalseEasting = 500000.0;

  /// UTM false northing (janubiy yarim shar uchun).
  static const double utmFalseNorthingSouth = 10000000.0;

  /// UTM zone kengligi (gradus).
  static const double utmZoneWidthDeg = 6.0;

  /// UTM amal qiladigan kenglik oralig'i.
  static const double utmMinLat = -80.0;
  static const double utmMaxLat = 84.0;

  /// UTM inversiyasidagi uzunlik qisqichi (markaziy meridiandan maksimal chetlik, gradus).
  /// Zona kengligi 6° bo‘lib, markazdan teorik chek ±3°; bu yerda ~±3.85° —
  /// transform narxi, chekka effektlar va `[toLatLngFromUtmMeters]` ichidagi
  /// qisqichning zonadan chiqmasligini taminlash uchun biroz zaxira.
  static const double utmInverseLngHalfWidthDeg = 3.85;

  // ── Konvertatsiya ─────────────────────────────────────────────────────────
  /// Radian → daraja koeffitsiyenti: 180/π.
  static const double radToDeg = 180.0 / 3.141592653589793;

  /// Daraja → radian koeffitsiyenti: π/180.
  static const double degToRad = 3.141592653589793 / 180.0;

  // ── Yer Magnetizmi ────────────────────────────────────────────────────────
  /// WMM model amal qilish oralig'i (yil).
  /// 2025 versiyasi 2025.0 — 2030.0 orasida ishlatiladi.
  static const double wmmEpoch = 2025.0;
  static const double wmmValidYears = 5.0;
}
