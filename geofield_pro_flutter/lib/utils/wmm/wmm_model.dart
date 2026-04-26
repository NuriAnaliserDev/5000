import 'dart:math' as math;

import '../geo/geo_constants.dart';
import 'wmm_coefficients_2025.dart';

/// World Magnetic Model 2025 — geomagnitik maydonning sferik garmonik
/// hisoblovchi modul.
///
/// Kirish: geografik kenglik/uzunlik, balandlik, sana.
/// Chiqish: declination (D), inclination (I), total intensity (F),
/// horizontal intensity (H).
///
/// Aniqlik: ±0.5° declination, ±0.5° inclination, ±150 nT intensity.
/// Ref: Chulliat et al. (2024), "The World Magnetic Model for 2025".
///
/// Bu engine bitta marta yaratiladi (`.load()`), keyin hamma joyda
/// qayta ishlatish mumkin.
class WmmModel {
  /// Degree 1..n, Order 0..n koeffitsiyentlar, yilli tuzatilgan.
  final List<List<double>> _g; // g[n][m]
  final List<List<double>> _h; // h[n][m]
  final List<List<double>> _gDot;
  final List<List<double>> _hDot;
  final double _epochYear;

  WmmModel._({
    required List<List<double>> g,
    required List<List<double>> h,
    required List<List<double>> gDot,
    required List<List<double>> hDot,
    required double epochYear,
  })  : _g = g,
        _h = h,
        _gDot = gDot,
        _hDot = hDot,
        _epochYear = epochYear;

  /// Ichki koeffitsiyentlardan model yaratadi.
  factory WmmModel.embedded() {
    final g = List.generate(wmmMaxDegree + 1,
        (_) => List.filled(wmmMaxDegree + 1, 0.0, growable: false));
    final h = List.generate(wmmMaxDegree + 1,
        (_) => List.filled(wmmMaxDegree + 1, 0.0, growable: false));
    final gDot = List.generate(wmmMaxDegree + 1,
        (_) => List.filled(wmmMaxDegree + 1, 0.0, growable: false));
    final hDot = List.generate(wmmMaxDegree + 1,
        (_) => List.filled(wmmMaxDegree + 1, 0.0, growable: false));

    for (final row in wmmCoefficients2025) {
      final n = row[0].toInt();
      final m = row[1].toInt();
      if (n > wmmMaxDegree) continue;
      g[n][m] = row[2];
      h[n][m] = row[3];
      gDot[n][m] = row[4];
      hDot[n][m] = row[5];
    }

    return WmmModel._(
      g: g,
      h: h,
      gDot: gDot,
      hDot: hDot,
      epochYear: wmmEpoch2025,
    );
  }

  /// Hozirgi sana uchun decimal year (2026-04-23 → 2026.311).
  static double decimalYear(DateTime date) {
    final startOfYear = DateTime(date.year);
    final nextYear = DateTime(date.year + 1);
    final fraction = date.difference(startOfYear).inSeconds /
        nextYear.difference(startOfYear).inSeconds;
    return date.year + fraction;
  }

  /// Asosiy hisob — geografik (φ, λ, h)'dan magnit maydonni topish.
  ///
  /// - [lat]: geografik kenglik (daraja, -90..+90)
  /// - [lng]: geografik uzunlik (daraja, -180..+180)
  /// - [altitudeKm]: dengiz sathidan balandlik (km, odatda 0 dala uchun)
  /// - [date]: hisoblash sanasi (default: bugun)
  GeoMagneticField calculate({
    required double lat,
    required double lng,
    double altitudeKm = 0.0,
    DateTime? date,
  }) {
    final t = decimalYear(date ?? DateTime.now());
    final dt = t - _epochYear;

    // Geodetic → geocentric (spherical) transform.
    final latRad = lat * GeoConstants.degToRad;
    final lngRad = lng * GeoConstants.degToRad;

    // WGS84 ellipsoid → ayniy sferik radius.
    const double a = GeoConstants.wgs84A / 1000.0; // km
    const double b = GeoConstants.wgs84B / 1000.0; // km
    final cosLat = math.cos(latRad);
    final sinLat = math.sin(latRad);
    final rc = math.sqrt(
      ((a * a * cosLat) * (a * a * cosLat) + (b * b * sinLat) * (b * b * sinLat)) /
          ((a * cosLat) * (a * cosLat) + (b * sinLat) * (b * sinLat)),
    );
    final r = math.sqrt(
      altitudeKm * altitudeKm +
          2 * altitudeKm * rc +
          (a * a * a * a * cosLat * cosLat + b * b * b * b * sinLat * sinLat) /
              (a * a * cosLat * cosLat + b * b * sinLat * sinLat),
    );

    // Geodetic → geocentric latitude
    final cd = (altitudeKm + rc) * cosLat / r;
    final sd = (altitudeKm * sinLat +
            (a * a * sinLat) /
                math.sqrt(a * a * cosLat * cosLat + b * b * sinLat * sinLat)) /
        r;
    final sinGcLat = sd;
    final cosGcLat = cd;
    final gcLat = math.atan2(sinGcLat, cosGcLat);

    // Ortonormallashgan (Schmidt) Legendre funksiyalar.
    const double aRef = 6371.2; // km — WMM reference radius
    final ratio = aRef / r;

    // Compute P[n][m] — Schmidt semi-normalized associated Legendre
    final p = _schmidtLegendre(gcLat);
    final dp = _schmidtLegendreDeriv(gcLat, p);

    double br = 0.0; // Radial component
    double bTheta = 0.0; // Colatitude component
    double bPhi = 0.0; // Longitude component

    double ratioPow = ratio * ratio; // (a/r)^(n+2), boshlanadi n=1 → ^3, oshiradi
    for (int n = 1; n <= wmmMaxDegree; n++) {
      ratioPow *= ratio; // now (a/r)^(n+2)

      for (int m = 0; m <= n; m++) {
        final gt = _g[n][m] + dt * _gDot[n][m];
        final ht = _h[n][m] + dt * _hDot[n][m];

        final cosMLng = math.cos(m * lngRad);
        final sinMLng = math.sin(m * lngRad);

        final gCos = gt * cosMLng;
        final hSin = ht * sinMLng;
        final gSin = gt * sinMLng;
        final hCos = ht * cosMLng;

        br += (n + 1) * ratioPow * (gCos + hSin) * p[n][m];
        bTheta -= ratioPow * (gCos + hSin) * dp[n][m];
        if (cosGcLat.abs() > 1e-10) {
          bPhi -= ratioPow * m * (-gSin + hCos) * p[n][m] / cosGcLat;
        }
      }
    }

    // Geocentric → geodetic (kichik farq)
    final gcLatDiff = gcLat - latRad;
    final bx = -bTheta * math.cos(gcLatDiff) - br * math.sin(gcLatDiff);
    final by = bPhi;
    final bz = bTheta * math.sin(gcLatDiff) - br * math.cos(gcLatDiff);

    final h = math.sqrt(bx * bx + by * by);
    final f = math.sqrt(h * h + bz * bz);
    final decDeg = math.atan2(by, bx) * GeoConstants.radToDeg;
    final incDeg = math.atan2(bz, h) * GeoConstants.radToDeg;

    return GeoMagneticField(
      declination: decDeg,
      inclination: incDeg,
      horizontalIntensity: h,
      totalIntensity: f,
      northComponent: bx,
      eastComponent: by,
      downComponent: bz,
      modelEpoch: _epochYear,
      decimalYear: t,
    );
  }

  /// Soddalashgan declination — dala uchun ko'p ishlatiladi.
  double declination({
    required double lat,
    required double lng,
    double altitudeKm = 0.0,
    DateTime? date,
  }) =>
      calculate(lat: lat, lng: lng, altitudeKm: altitudeKm, date: date)
          .declination;

  /// Schmidt semi-normalized associated Legendre polynomials P[n][m]
  /// (kenglik bo'yicha), Gauss-Legendre rekursiya.
  List<List<double>> _schmidtLegendre(double gcLat) {
    final sinLat = math.sin(gcLat);
    // cosLat used indirectly via sinLat in recursion; keeping dim arrays.
    final p = List.generate(
      wmmMaxDegree + 1,
      (_) => List<double>.filled(wmmMaxDegree + 1, 0.0, growable: false),
    );
    p[0][0] = 1.0;

    for (int n = 1; n <= wmmMaxDegree; n++) {
      for (int m = 0; m <= n; m++) {
        if (n == m) {
          final prev = n == 1 ? 1.0 : p[n - 1][n - 1];
          p[n][m] = math.sqrt(1 - sinLat * sinLat) *
              prev *
              (n == 1 ? 1.0 : math.sqrt((2.0 * n - 1) / (2.0 * n)));
        } else if (n == 1 || m == n - 1) {
          p[n][m] = sinLat * p[n - 1][m] * math.sqrt((2.0 * n - 1));
        } else {
          final k = ((n - 1) * (n - 1) - m * m) / ((2.0 * n - 1) * (2.0 * n - 3));
          p[n][m] = sinLat * p[n - 1][m] - math.sqrt(k) * p[n - 2][m];
          p[n][m] /= math.sqrt(1.0 - k);
        }
      }
    }
    return p;
  }

  /// dP/dθ — Schmidt Legendre hosilasi.
  List<List<double>> _schmidtLegendreDeriv(
      double gcLat, List<List<double>> p) {
    final sinLat = math.sin(gcLat);
    final cosLat = math.cos(gcLat);
    final dp = List.generate(
      wmmMaxDegree + 1,
      (_) => List<double>.filled(wmmMaxDegree + 1, 0.0, growable: false),
    );
    for (int n = 1; n <= wmmMaxDegree; n++) {
      for (int m = 0; m <= n; m++) {
        if (n == m) {
          dp[n][m] = (m == 0 ? -n : 0) * sinLat * p[n][m] / math.max(cosLat, 1e-10);
        } else {
          // Numerik hosila: cosθ · (dP/dsinθ)
          final factor = math.sqrt((n + m) * (n - m + 1.0));
          if (m > 0) {
            dp[n][m] = cosLat * (factor * p[n][m - 1] - m * sinLat * p[n][m] / math.max(cosLat, 1e-10));
          } else {
            // Central recursion
            if (n > 1) {
              dp[n][0] = cosLat *
                  math.sqrt(n * (n + 1.0) / 2.0) *
                  (p[n][1]);
            } else {
              dp[1][0] = cosLat;
            }
          }
        }
      }
    }
    return dp;
  }
}

/// Sferik garmonik model natijasi — magnit maydon komponentlari.
class GeoMagneticField {
  /// Declination — magnitni shimoli va geografik shimol orasidagi burchak
  /// (daraja, sharq tomonga musbat).
  final double declination;

  /// Inclination — magnitik vektori va gorizontal orasidagi burchak
  /// (daraja, pastga tushsa musbat — shimoliy yarim sharda odatda musbat).
  final double inclination;

  /// Horizontal intensity (nT).
  final double horizontalIntensity;

  /// Total intensity (nT).
  final double totalIntensity;

  /// Shimol komponenti (nT, geodetic frame).
  final double northComponent;

  /// Sharq komponenti (nT).
  final double eastComponent;

  /// Pastga komponenti (nT).
  final double downComponent;

  /// Model epoch (yil, koeffitsiyentlar aniq bo'lgan vaqt).
  final double modelEpoch;

  /// Hisoblash vaqti (decimal year).
  final double decimalYear;

  const GeoMagneticField({
    required this.declination,
    required this.inclination,
    required this.horizontalIntensity,
    required this.totalIntensity,
    required this.northComponent,
    required this.eastComponent,
    required this.downComponent,
    required this.modelEpoch,
    required this.decimalYear,
  });
}
