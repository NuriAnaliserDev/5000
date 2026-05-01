import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'geo_constants.dart';

/// UTM (Universal Transverse Mercator) koordinata strukturasi.
///
/// Oddiy `String`'dan farqli — eksport, tahlil va boshqa dasturlarga
/// (QGIS, AutoCAD) uzatishda har maydon alohida ishlatilishi mumkin.
///
/// Aniqlik: ~0.001m bitta UTM zona ichida (Redfearn 5/6 darajali seriya,
/// FieldMove va QGIS bilan teng).
class UtmCoord {
  /// UTM zona raqami (1..60).
  final int zone;

  /// Shimoliy yarim sharda bo'lsa `true`, janubiy yarim sharda `false`.
  final bool isNorth;

  /// Easting (metr). False easting = 500,000.
  final double easting;

  /// Northing (metr). Janubiy yarim shar uchun +10,000,000.
  final double northing;

  /// Meridian konvergensiyasi (daraja) — gratik shimol va xarita shimoli farqi.
  /// Muhim: geologik xarita shimoli UTM shimolidan meridian konvergentsiya
  /// qadar farq qiladi. Dala tekshirish uchun muhim.
  final double meridianConvergence;

  /// Point scale factor (nuqtali masshtab omil).
  /// Zona chekkasida ~1.00001, markaziy meridianda 0.9996.
  final double pointScaleFactor;

  const UtmCoord({
    required this.zone,
    required this.isNorth,
    required this.easting,
    required this.northing,
    required this.meridianConvergence,
    required this.pointScaleFactor,
  });

  /// Sentinel qiymat: "UTM oralig'idan tashqari" (qutb mintaqalari).
  static const UtmCoord outOfRange = UtmCoord(
    zone: 0,
    isNorth: true,
    easting: 0.0,
    northing: 0.0,
    meridianConvergence: 0.0,
    pointScaleFactor: double.nan,
  );

  bool get isValid => zone != 0;
  String get hemisphere => isNorth ? 'N' : 'S';

  /// Qisqa ko'rinish: "42N 404123 4620512".
  String get shortDisplay => '$zone$hemisphere '
      '${easting.toStringAsFixed(0)} '
      '${northing.toStringAsFixed(0)}';

  /// To'liq ko'rinish: "42N  E: 404123  N: 4620512".
  String get display => '$zone$hemisphere  '
      'E: ${easting.toStringAsFixed(0)}  '
      'N: ${northing.toStringAsFixed(0)}';

  /// Map formatida — eksport uchun qulay.
  Map<String, dynamic> toMap() => {
    'zone': zone,
    'hemisphere': hemisphere,
    'easting': easting,
    'northing': northing,
    'meridianConvergence': meridianConvergence,
    'pointScaleFactor': pointScaleFactor,
  };

  /// Lat/Lng dan UTM ga aylantirish (Redfearn 5/6 darajali seriya).
  ///
  /// Ref: Snyder, J.P., "Map Projections — A Working Manual",
  /// USGS Professional Paper 1395, 1987, Ch. 8.
  ///
  /// Aniqlik: ~0.001m bitta UTM zona ichida (WGS84).
  static UtmCoord fromLatLng(double lat, double lng) {
    if (lat < GeoConstants.utmMinLat || lat > GeoConstants.utmMaxLat) {
      return outOfRange;
    }

    final double latRad = lat * GeoConstants.degToRad;
    final double lngRad = lng * GeoConstants.degToRad;

    final int zone = ((lng + 180.0) / GeoConstants.utmZoneWidthDeg).floor() + 1;
    final double lng0Deg = (zone - 1) * GeoConstants.utmZoneWidthDeg - 180.0 + 3.0;
    final double lng0Rad = lng0Deg * GeoConstants.degToRad;

    const double a = GeoConstants.wgs84A;
    const double k0 = GeoConstants.utmK0;
    const double e2 = GeoConstants.wgs84E2;
    const double ePrime2 = GeoConstants.wgs84EPrime2;

    final double sinLat = math.sin(latRad);
    final double cosLat = math.cos(latRad);
    final double cosLat2 = cosLat * cosLat;
    final double cosLat3 = cosLat2 * cosLat;
    final double cosLat4 = cosLat2 * cosLat2;
    final double cosLat5 = cosLat4 * cosLat;
    final double cosLat6 = cosLat4 * cosLat2;

    final double t = math.tan(latRad);
    final double t2 = t * t;
    final double t4 = t2 * t2;

    final double n = a / math.sqrt(1 - e2 * sinLat * sinLat);

    // Meridian yoyi (M)
    final double m = a *
        ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * math.pow(e2, 3) / 256) * latRad -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * math.pow(e2, 3) / 1024) *
                math.sin(2 * latRad) +
            (15 * e2 * e2 / 256 + 45 * math.pow(e2, 3) / 1024) *
                math.sin(4 * latRad) -
            (35 * math.pow(e2, 3) / 3072) * math.sin(6 * latRad));

    final double dL = lngRad - lng0Rad;
    final double dL2 = dL * dL;
    final double dL3 = dL2 * dL;
    final double dL4 = dL3 * dL;
    final double dL5 = dL4 * dL;
    final double dL6 = dL5 * dL;

    final double easting = GeoConstants.utmFalseEasting +
        k0 *
            n *
            (dL * cosLat +
                (dL3 * cosLat3 / 6.0) * (1 - t2 + ePrime2 * cosLat2) +
                (dL5 * cosLat5 / 120.0) *
                    (5 - 18 * t2 + t4 + 72 * ePrime2 * cosLat2 - 58 * ePrime2));

    final double northingOffset =
        lat < 0 ? GeoConstants.utmFalseNorthingSouth : 0.0;
    final double northing = northingOffset +
        k0 *
            (m +
                n *
                    t *
                    ((dL2 * cosLat2 / 2.0) +
                        (dL4 * cosLat4 / 24.0) *
                            (5 -
                                t2 +
                                9 * ePrime2 * cosLat2 +
                                4 * ePrime2 * ePrime2 * cosLat4) +
                        (dL6 * cosLat6 / 720.0) *
                            (61 -
                                58 * t2 +
                                t4 +
                                600 * ePrime2 * cosLat2 -
                                330 * ePrime2)));

    // Meridian konvergensiyasi (γ) — daraja
    // γ ≈ (λ - λ₀) × sin(φ) [1 + ... high order terms]
    final double gammaRad = dL * sinLat +
        (dL3 / 3.0) *
            sinLat *
            cosLat2 *
            (1 + 3 * ePrime2 * cosLat2 + 2 * ePrime2 * ePrime2 * cosLat4);

    // Point scale factor (k)
    final double kScale = k0 *
        (1 +
            (dL2 * cosLat2 / 2.0) * (1 + ePrime2 * cosLat2) +
            (dL4 * cosLat4 / 24.0) *
                (5 - 4 * t2 + 14 * ePrime2 * cosLat2 + 13 * ePrime2 * ePrime2 * cosLat4));

    return UtmCoord(
      zone: zone,
      isNorth: lat >= 0,
      easting: easting,
      northing: northing,
      meridianConvergence: gammaRad * GeoConstants.radToDeg,
      pointScaleFactor: kScale,
    );
  }

  /// UTM (sharqiy/shimoliy, metr) → WGS-84.
  ///
  /// Dikkat: [fromLatLng] janubda ham `northing` 10M dan kichik bo‘lishi mumkin
  /// (10M + manfiy meridian qismi), shuning uchun `northing >= 10M` bilan yarim
  /// shar ajratish xato bo‘ladi — ikki kenglik oraliqi tekshiriladi.
  static LatLng toLatLngFromUtmMeters({
    required int zone,
    required double easting,
    required double northing,
    double? hintLatitude,
  }) {
    if (zone < 1 || zone > 60) {
      return const LatLng(0, 0);
    }
    final lng0 = (zone - 1) * GeoConstants.utmZoneWidthDeg - 180.0 + 3.0;

    final candNorth =
        _utmBinaryLatSearch(easting, northing, lng0, 0.0, GeoConstants.utmMaxLat);
    final candSouth = _utmBinaryLatSearch(easting, northing, lng0, -80.0, 0.0);

    double errOf(LatLng c) {
      final u = UtmCoord.fromLatLng(c.latitude, c.longitude);
      if (!u.isValid) return double.infinity;
      final de = u.easting - easting;
      final dn = u.northing - northing;
      return de * de + dn * dn;
    }

    final errN = errOf(candNorth);
    final errS = errOf(candSouth);

    LatLng best;
    if (hintLatitude != null) {
      if (hintLatitude < -5 && errS < errN) {
        best = candSouth;
      } else if (hintLatitude > 5 && errN < errS) {
        best = candNorth;
      } else {
        best = errN < errS ? candNorth : candSouth;
      }
    } else {
      best = errN < errS ? candNorth : candSouth;
    }

    var lat = best.latitude;
    var lng = best.longitude;

    const lngClamp = GeoConstants.utmInverseLngHalfWidthDeg;
    for (var p = 0; p < 14; p++) {
      final u = UtmCoord.fromLatLng(lat, lng);
      if (!u.isValid) break;
      final dE = easting - u.easting;
      final dN = northing - u.northing;
      if (dE * dE + dN * dN < 1e-4) break;
      const h = 1e-6;
      final uLat = UtmCoord.fromLatLng(lat + h, lng);
      final uLng = UtmCoord.fromLatLng(lat, lng + h);
      if (!uLat.isValid || !uLng.isValid) break;
      final dEdLat = (uLat.easting - u.easting) / h;
      final dNdLat = (uLat.northing - u.northing) / h;
      final dEdLng = (uLng.easting - u.easting) / h;
      final dNdLng = (uLng.northing - u.northing) / h;
      final det = dEdLat * dNdLng - dEdLng * dNdLat;
      if (det.abs() < 1e-22) break;
      lat += 0.45 * (dNdLng * dE - dEdLng * dN) / det;
      lng += 0.45 * (-dNdLat * dE + dEdLat * dN) / det;
      lat = lat.clamp(GeoConstants.utmMinLat, GeoConstants.utmMaxLat);
      lng = lng.clamp(lng0 - lngClamp, lng0 + lngClamp);
    }

    return LatLng(
      lat.clamp(GeoConstants.utmMinLat, GeoConstants.utmMaxLat),
      lng.clamp(-180.0, 180.0),
    );
  }

  static LatLng _utmBinaryLatSearch(
    double easting,
    double northing,
    double lng0,
    double lo,
    double hi,
  ) {
    var a = lo;
    var b = hi;
    for (var i = 0; i < 72; i++) {
      final mid = (a + b) / 2;
      var lng = lng0 +
          (easting - GeoConstants.utmFalseEasting) /
              (111320.0 * math.cos(mid * GeoConstants.degToRad).clamp(0.05, 1.0));
      lng = lng.clamp(
        lng0 - GeoConstants.utmInverseLngHalfWidthDeg,
        lng0 + GeoConstants.utmInverseLngHalfWidthDeg,
      );
      final u = UtmCoord.fromLatLng(mid, lng);
      if (!u.isValid) {
        b = mid;
        continue;
      }
      // Kenglik oshishi bilan UTM `northing` (janubda ham, 10M+Qo formula bilan)
      // monoton o‘sadi; shuning uchun shimol (0..84) va janub (-80..0) oralig‘ida
      // bir xil taqqoslash: kichikroq `northing` → pastroq kenglikdan yuqoriga siljish.
      if (u.northing < northing) {
        a = mid;
      } else {
        b = mid;
      }
    }

    final lat = (a + b) / 2;
    final lng = lng0 +
        (easting - GeoConstants.utmFalseEasting) /
            (111320.0 * math.cos(lat * GeoConstants.degToRad).clamp(0.05, 1.0));
    return LatLng(
      lat.clamp(GeoConstants.utmMinLat, GeoConstants.utmMaxLat),
      lng.clamp(
        lng0 - GeoConstants.utmInverseLngHalfWidthDeg,
        lng0 + GeoConstants.utmInverseLngHalfWidthDeg,
      ),
    );
  }
}
