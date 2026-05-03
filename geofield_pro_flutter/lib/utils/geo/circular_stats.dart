import 'dart:math' as math;

import 'geo_constants.dart';

/// Sirkulyar (yo'naltirilgan ma'lumot) statistikalari.
///
/// **Muhim farqlar:**
/// - **Unimodal (arrow)**: azimuth, heading (0..360° — 350° va 10° alohida).
/// - **Axial (line)**: strike, lineation (0..180° — 350° va 170° = 350°).
///
/// Qatlamning strike'i — chiziq, ya'ni strike=10° va strike=190° **aynan
/// bir xil narsa**. Oddiy arifmetik yoki oddiy vektor o'rtacha bu yerda
/// noto'g'ri natija beradi. To'g'ri usul: 2·θ bilan ishlash (doubling),
/// so'ng natijani 2 ga bo'lish.
///
/// Ref: Fisher, N.I. (1993), "Statistical Analysis of Circular Data".
class CircularStats {
  CircularStats._();

  // ═══════════════════════════════════════════════════════════════════════════
  // UNIMODAL (Azimuth / Arrow data) — 0..360°
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vektorial o'rtacha (unimodal), daraja (0..360).
  ///
  /// [350°, 10°] → 0° (to'g'ri), arifmetik o'rtacha 180° (noto'g'ri).
  static double unimodalMean(List<double> angles) {
    if (angles.isEmpty) return double.nan;
    double sumSin = 0, sumCos = 0;
    for (final a in angles) {
      final rad = a * GeoConstants.degToRad;
      sumSin += math.sin(rad);
      sumCos += math.cos(rad);
    }
    final meanRad = math.atan2(sumSin, sumCos);
    return ((meanRad * GeoConstants.radToDeg) + 360) % 360;
  }

  /// Unimodal resultant length — vektorlarning yig'indi uzunligi bo'linadi n.
  /// 0..1 orasida; 1 ga yaqin → zich, 0 ga yaqin → tarqoq.
  static double unimodalResultantLength(List<double> angles) {
    if (angles.isEmpty) return 0.0;
    double sumSin = 0, sumCos = 0;
    for (final a in angles) {
      final rad = a * GeoConstants.degToRad;
      sumSin += math.sin(rad);
      sumCos += math.cos(rad);
    }
    return math.sqrt(sumSin * sumSin + sumCos * sumCos) / angles.length;
  }

  /// Unimodal standart og'ish (daraja).
  /// Ref: Mardia & Jupp (2000), Eq. 2.3.14.
  static double unimodalStdDev(List<double> angles) {
    if (angles.isEmpty) return double.nan;
    final r = unimodalResultantLength(angles);
    if (r >= 1.0) return 0.0;
    return math.sqrt(-2 * math.log(r)) * GeoConstants.radToDeg;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AXIAL (Line / Strike data) — 0..180° effektiv
  // ═══════════════════════════════════════════════════════════════════════════

  /// Axial (ikki tomonlama) o'rtacha, daraja (0..360°).
  /// Kiritilgan `lines` 0..360° bo'lishi mumkin — avtomatik 0..180°ga siqadi.
  ///
  /// Algoritm:
  ///   1. Har burchakni ikki baravar qilamiz (2θ).
  ///   2. Unimodal mean — 2θ uchun.
  ///   3. Natijani 2 ga bo'lamiz → 0..180°.
  ///
  /// [strike=10, 190] → axial mean = 10° (to'g'ri),
  /// [strike=350, 10] → axial mean = 0° (to'g'ri; line aynan bir).
  static double axialMean(List<double> lines) {
    if (lines.isEmpty) return double.nan;
    final doubled = lines.map((s) => (2 * s) % 360).toList();
    final mean2 = unimodalMean(doubled);
    return mean2 / 2.0;
  }

  /// Axial resultant length (0..1).
  /// 1 ga yaqin → barcha lines taxminan bir tomonlama.
  static double axialResultantLength(List<double> lines) {
    if (lines.isEmpty) return 0.0;
    final doubled = lines.map((s) => (2 * s) % 360).toList();
    return unimodalResultantLength(doubled);
  }

  /// Axial standart og'ish (daraja).
  /// Natija 0..90° (axial dispersion).
  static double axialStdDev(List<double> lines) {
    if (lines.isEmpty) return double.nan;
    final doubled = lines.map((s) => (2 * s) % 360).toList();
    return unimodalStdDev(doubled) / 2.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FISHER STATISTICS (Unimodal 2D va 3D)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fisher 2D (unimodal circular) statistikasi — azimuth data uchun.
  static FisherStats2D fisher2D(List<double> angles) {
    final n = angles.length;
    if (n < 2) {
      return FisherStats2D._(
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
      final rad = a * GeoConstants.degToRad;
      sumSin += math.sin(rad);
      sumCos += math.cos(rad);
    }
    final r = math.sqrt(sumSin * sumSin + sumCos * sumCos);
    final rBar = r / n;

    final meanRad = math.atan2(sumSin, sumCos);
    final meanAngle = ((meanRad * GeoConstants.radToDeg) + 360) % 360;

    // Best & Fisher (1981) kappa estimator
    double kappa;
    if (rBar < 0.53) {
      kappa = 2 * rBar + math.pow(rBar, 3) + (5 * math.pow(rBar, 5)) / 6;
    } else if (rBar < 0.85) {
      kappa = -0.4 + 1.39 * rBar + 0.43 / (1 - rBar);
    } else {
      kappa = 1 / (math.pow(rBar, 3) - 4 * math.pow(rBar, 2) + 3 * rBar);
    }

    // α₉₅ — Fisher 1953 95% ishonch konusi
    double alpha95 = double.nan;
    if (r > 0 && n > 2) {
      final exponent = 1.0 / (n - 1);
      final p20 = math.pow(20.0, exponent) - 1.0;
      final cosAlpha = 1.0 - ((n - r) / r) * p20;
      if (cosAlpha >= -1.0 && cosAlpha <= 1.0) {
        alpha95 = math.acos(cosAlpha) * GeoConstants.radToDeg;
      } else if (cosAlpha > 1.0) {
        alpha95 = 0.0;
      } else {
        alpha95 = 90.0;
      }
    }

    return FisherStats2D._(
      n: n,
      meanAngle: meanAngle,
      resultantLength: rBar,
      kappa: (kappa.isNaN || kappa.isInfinite) ? 0 : kappa,
      alpha95: alpha95,
      isReliable: rBar > 0.5 && n >= 5,
    );
  }

  /// Fisher 3D (sferik) — plane normal vektorlari ro'yxati uchun.
  ///
  /// Kirish: ro'yxatdagi har element — [dipDir, dip] juftligi.
  /// Chiqish: 3D Fisher statistikasi (haqiqiy geologik Fisher).
  ///
  /// Bu — strike'dan 2D Fisher emas, balki to'g'ri 3D pole statistikasi.
  /// QField/FieldMove/GeoKit shu usuldan foydalanadi.
  static FisherStats3D fisher3D(List<({double dipDir, double dip})> poles) {
    final n = poles.length;
    if (n < 2) {
      return FisherStats3D._(
        n: n,
        meanDipDir: n == 1 ? poles[0].dipDir : double.nan,
        meanDip: n == 1 ? poles[0].dip : double.nan,
        resultantLength: n == 1 ? 1.0 : 0.0,
        kappa: double.nan,
        alpha95: double.nan,
        isReliable: false,
      );
    }

    // Har pole → unit vector (x, y, z) — lower hemisphere convention.
    double sx = 0, sy = 0, sz = 0;
    for (final p in poles) {
      // Pole trend = dipDir + 180, pole plunge = 90 - dip.
      final trendRad = ((p.dipDir + 180) % 360) * GeoConstants.degToRad;
      final plungeRad = (90 - p.dip) * GeoConstants.degToRad;
      // x=East, y=North, z=Down
      final cosPl = math.cos(plungeRad);
      sx += cosPl * math.sin(trendRad);
      sy += cosPl * math.cos(trendRad);
      sz += math.sin(plungeRad);
    }

    final r = math.sqrt(sx * sx + sy * sy + sz * sz);
    final rBar = r / n;

    // Mean vector → back to dipDir/dip
    final mx = sx / r;
    final my = sy / r;
    final mz = sz / r;
    final meanTrend = (math.atan2(mx, my) * GeoConstants.radToDeg + 360) % 360;
    final meanPlunge = math.asin(mz.clamp(-1.0, 1.0)) * GeoConstants.radToDeg;
    final meanDipDir = (meanTrend + 180) % 360;
    final meanDip = 90 - meanPlunge;

    // 3D Fisher kappa & α₉₅
    double kappa;
    if (rBar < 0.9 && n > 2) {
      kappa = (n - 1) / (n - r);
    } else if (n > 2) {
      // Approximation for tightly clustered data
      kappa = (n - 2) / (n - r);
    } else {
      kappa = double.nan;
    }

    double alpha95 = double.nan;
    if (r > 0 && n > 2) {
      // Fisher (1953): cos α₉₅ = 1 - ((N-R)/R) × [(1/0.05)^(1/(N-1)) - 1]
      final exponent = 1.0 / (n - 1);
      final p20 = math.pow(20.0, exponent) - 1.0;
      final cosAlpha = 1.0 - ((n - r) / r) * p20;
      if (cosAlpha >= -1.0 && cosAlpha <= 1.0) {
        alpha95 = math.acos(cosAlpha) * GeoConstants.radToDeg;
      } else if (cosAlpha > 1.0) {
        alpha95 = 0.0;
      } else {
        alpha95 = 90.0;
      }
    }

    return FisherStats3D._(
      n: n,
      meanDipDir: meanDipDir,
      meanDip: meanDip,
      resultantLength: rBar,
      kappa: (kappa.isNaN || kappa.isInfinite) ? 0 : kappa,
      alpha95: alpha95,
      isReliable: rBar > 0.7 && n >= 5,
    );
  }
}

/// 2D Fisher natijasi — unimodal circular data.
class FisherStats2D {
  final int n;
  final double meanAngle;
  final double resultantLength;
  final double kappa;
  final double alpha95;
  final bool isReliable;

  const FisherStats2D._({
    required this.n,
    required this.meanAngle,
    required this.resultantLength,
    required this.kappa,
    required this.alpha95,
    required this.isReliable,
  });
}

/// 3D Fisher natijasi — qatlam qutblari (poles) uchun.
/// Bu haqiqiy geologik Fisher statistikasi.
class FisherStats3D {
  final int n;

  /// O'rta dip direction (0..360°).
  final double meanDipDir;

  /// O'rta dip (0..90°).
  final double meanDip;

  /// Resultant length (0..1).
  final double resultantLength;

  /// Concentration parameter κ.
  final double kappa;

  /// 95% ishonch konusi (daraja).
  final double alpha95;

  final bool isReliable;

  const FisherStats3D._({
    required this.n,
    required this.meanDipDir,
    required this.meanDip,
    required this.resultantLength,
    required this.kappa,
    required this.alpha95,
    required this.isReliable,
  });
}
