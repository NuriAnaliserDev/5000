import 'dart:math';

import 'geo/utm_coord.dart';

export 'geo/stereonet_engine.dart' show StereonetEngine, StereonetProjection, ProjectedPoint;

class GeologyUtils {
  /// Converts Decimal Degrees to DMS format.
  static String toDMS(double degree, bool isLat) {
    String direction = isLat
        ? (degree >= 0 ? 'N' : 'S')
        : (degree >= 0 ? 'E' : 'W');

    degree = degree.abs();
    int d = degree.floor();
    int m = ((degree - d) * 60).floor();
    double s = (degree - d - m / 60) * 3600;

    return "$d°$m'${s.toStringAsFixed(1)}\"$direction";
  }

  /// Calculates Dip Direction from Strike and Dip.
  /// Assuming Strike follows right-hand rule (Dip is 90° clockwise from Strike).
  static double calculateDipDirection(double strike) {
    return (strike + 90) % 360;
  }

  /// UTM proyeksiya — strukturalangan natija [UtmCoord] qaytaradi.
  ///
  /// Aniqlik: ~0.001m bitta UTM zona ichida (Redfearn 5/6 darajali seriya,
  /// WGS84 ellipsoidi). QField va FieldMove darajasi.
  static UtmCoord toUtm(double lat, double lng) => UtmCoord.fromLatLng(lat, lng);

  /// UTM proyeksiyasining matn ko'rinishi. Eski kod uchun qoldirilgan.
  ///
  /// Yangi kodda to'g'ridan-to'g'ri `GeologyUtils.toUtm(lat, lng).display`
  /// yoki `UtmCoord.fromLatLng(lat, lng)` ishlatiladi.
  static String toUTM(double lat, double lng) {
    final utm = UtmCoord.fromLatLng(lat, lng);
    if (!utm.isValid) return 'Out of UTM range';
    return utm.display;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CIRCULAR STATISTICS (Directional Data — Geologik Statistika)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Circular Mean — Vektorial o'rtacha burchak (degrees, 0–360).
  ///
  /// Oddiy arifmetik o'rtacha burchaklar uchun NOTO'G'RI.
  /// Masalan: [350°, 10°] → arifmetik: 180°, vektorial: 0° ✓
  ///
  /// [angles] — daraja (degree) ro'yxati.
  /// Returns NaN if list is empty.
  static double circularMean(List<double> angles) {
    if (angles.isEmpty) return double.nan;
    double sumSin = 0, sumCos = 0;
    for (final a in angles) {
      final rad = a * pi / 180;
      sumSin += sin(rad);
      sumCos += cos(rad);
    }
    final meanRad = atan2(sumSin, sumCos);
    return ((meanRad * 180 / pi) + 360) % 360;
  }

  /// Fisher Concentration — sferik ma'lumotlar uchun statistika.
  ///
  /// [angles] — daraja ro'yxati.
  static FisherStats fisherStats(List<double> angles) {
    final n = angles.length;
    if (n < 2) {
      return FisherStats(
        n: n,
        meanAngle: n == 1 ? angles[0] : double.nan,
        resultantLength: n == 1 ? 1.0 : 0.0,
        kappa: double.nan,
        alpha95: double.nan,
        isReliable: false,
      );
    }

    double sumSin = 0, sumCos = 0;
    for (final a in angles) {
      final rad = a * pi / 180;
      sumSin += sin(rad);
      sumCos += cos(rad);
    }
    final R = sqrt(sumSin * sumSin + sumCos * sumCos);
    final rBar = R / n;

    final meanRad = atan2(sumSin, sumCos);
    final meanAngle = ((meanRad * 180 / pi) + 360) % 360;

    // κ (kappa) — concentration parameter
    double kappa;
    if (rBar < 0.53) {
      kappa = 2 * rBar + pow(rBar, 3) + (5 * pow(rBar, 5)) / 6;
    } else if (rBar < 0.85) {
      kappa = -0.4 + 1.39 * rBar + 0.43 / (1 - rBar);
    } else {
      kappa = 1 / (pow(rBar, 3) - 4 * pow(rBar, 2) + 3 * rBar);
    }

    // α₉₅ — 95% ishonch konusi (Fisher 1953 standart formulasi)
    // α₉₅ = arccos(1 - ((n - R)/R) × (20^(1/(n-1)) - 1))
    double alpha95 = double.nan;
    if (R > 0 && n > 2) {
      final exponent = 1.0 / (n - 1);
      final p20 = pow(20.0, exponent) - 1.0; // 20^(1/(n-1)) - 1
      final cosAlpha = 1.0 - ((n - R) / R) * p20;
      if (cosAlpha >= -1.0 && cosAlpha <= 1.0) {
        alpha95 = acos(cosAlpha) * 180 / pi;
      } else if (cosAlpha > 1.0) {
        alpha95 = 0.0; // Juda kichik burchak (juda katta n yoki R)
      } else {
        alpha95 = 90.0; // Ishonchsiz — yetarli ma'lumot yo'q
      }
    }

    return FisherStats(
      n: n,
      meanAngle: meanAngle,
      resultantLength: rBar,
      kappa: (kappa.isNaN || kappa.isInfinite) ? 0 : kappa,
      alpha95: alpha95,
      isReliable: rBar > 0.5 && n >= 5,
    );
  }

  /// Circular Standard Deviation (degrees)
  static double circularStdDev(List<double> angles) {
    if (angles.isEmpty) return double.nan;
    double sumSin = 0, sumCos = 0;
    for (final a in angles) {
      sumSin += sin(a * pi / 180);
      sumCos += cos(a * pi / 180);
    }
    final R = sqrt(sumSin * sumSin + sumCos * sumCos) / angles.length;
    if (R >= 1.0) return 0.0;
    return sqrt(-2 * log(R)) * 180 / pi;
  }

  /// Apparent Dip in a given cross-section direction.
  ///
  /// [trueDip] — geological dip angle (0–90°)
  /// [dipDirection] — direction of true dip (0–360°)
  /// [sectionAzimuth] — direction of the cross-section (0–360°)
  static double apparentDip({
    required double trueDip,
    required double dipDirection,
    required double sectionAzimuth,
  }) {
    final beta = (dipDirection - sectionAzimuth) * pi / 180;
    final tanApparent = tan(trueDip * pi / 180) * cos(beta).abs();
    return atan(tanApparent) * 180 / pi;
  }

  /// O'lchov turining kichik turlarini qaytaradi.
  /// [station_structural_section.dart] tomonidan chaqiriladi.
  static List<String> getSubTypes(String measurementType) {
    switch (measurementType) {
      case 'bedding':
        return ['inclined', 'horizontal', 'vertical', 'overturned'];
      case 'cleavage':
        return ['axial_planar', 'crenulation', 'pressure_solution', 'disjunctive'];
      case 'lineation':
        return ['stretching', 'mineral', 'intersection', 'crenulation'];
      case 'joint':
        return ['systematic', 'non_systematic', 'extension', 'shear'];
      case 'contact':
        return ['intrusive', 'sedimentary', 'tectonic', 'unconformity'];
      case 'fault':
        return ['normal', 'reverse', 'strike_slip', 'oblique'];
      default:
        return ['inclined', 'horizontal', 'vertical'];
    }
  }

  /// Plunge va Trend dan Dip va Strike hisoblash (Lineatsiya uchun).
  /// [plunge] — 0..90°, [trend] — 0..360°
  /// Returns {strike, dip}
  static Map<String, double> plungeTrendToDipStrike(double plunge, double trend) {
    final plungeRad = plunge * pi / 180;
    final trendRad = trend * pi / 180;

    // Normal vektori
    final nx = cos(plungeRad) * sin(trendRad);
    final ny = cos(plungeRad) * cos(trendRad);
    final nz = -sin(plungeRad);

    // Strike = atan2(nx, ny) + 90
    var strike = atan2(nx, ny) * 180 / pi + 90;
    if (strike >= 360) strike -= 360;
    if (strike < 0) strike += 360;

    // Dip = arctan(nz / sqrt(nx²+ny²))
    final dip = atan2(nz.abs(), sqrt(nx * nx + ny * ny)) * 180 / pi;

    return {'strike': strike, 'dip': dip};
  }

  /// DEPRECATED: Faqat bitta holat (perpendikulyar gorizontal traverse)
  /// uchun to'g'ri bo'lgan oddiy formula. Yangi kodda
  /// [`ThicknessCalculator`](geo/thickness_calculator.dart) ishlatilsin —
  /// u uch xil holatni to'g'ri hisoblaydi (perpendicular / horizontal /
  /// dipping ground).
  @Deprecated('Use ThicknessCalculator instead — provides correct Palmer '
      '3-case formulas. Will be removed in v2.0.')
  static double trueThickness({
    required double apparentThickness,
    required double dip,
  }) {
    if (dip <= 0) return apparentThickness;
    return apparentThickness * sin(dip * pi / 180);
  }
}


/// Result of Fisher statistical analysis on directional data.
class FisherStats {
  final int n;
  final double meanAngle;
  final double resultantLength;
  final double kappa;
  final double alpha95;
  final bool isReliable;

  const FisherStats({
    required this.n,
    required this.meanAngle,
    required this.resultantLength,
    required this.kappa,
    required this.alpha95,
    required this.isReliable,
  });
}
