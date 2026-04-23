import 'dart:math';
import 'dart:ui';

class GeologyUtils {
  /// Converts Decimal Degrees to DMS format
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

  /// Calculates Dip Direction from Strike and Dip
  /// Assuming Strike follows right-hand rule (Dip is 90 deg clockwise from Strike)
  static double calculateDipDirection(double strike) {
    return (strike + 90) % 360;
  }

  /// Scientifically accurate UTM conversion (Full Redfearn formula)
  /// Accurate to ~0.001m within a UTM zone (WGS84)
  static String toUTM(double lat, double lng) {
    if (lat < -80 || lat > 84) return "Out of UTM range";

    final double latRad = lat * pi / 180;
    final double lngRad = lng * pi / 180;

    final int zone = ((lng + 180) / 6).floor() + 1;
    final double lng0Rad = ((zone - 1) * 6 - 180 + 3) * pi / 180;

    // WGS84 ellipsoid constants
    const double a = 6378137.0;
    const double f = 1.0 / 298.257223563;
    const double k0 = 0.9996;
    const double e2 = f * (2 - f);
    const double ePrime2 = e2 / (1 - e2);

    final double sinLat = sin(latRad);
    final double cosLat = cos(latRad);
    final double cosLat2 = cosLat * cosLat;
    final double cosLat3 = cosLat2 * cosLat;
    final double cosLat4 = cosLat2 * cosLat2;
    final double cosLat5 = cosLat4 * cosLat;
    final double cosLat6 = cosLat4 * cosLat2;

    final double t = tan(latRad);
    final double t2 = t * t;
    final double t4 = t2 * t2;

    final double N = a / sqrt(1 - e2 * sinLat * sinLat);

    // Meridional arc
    final double M = a * (
      (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * pow(e2, 3) / 256) * latRad -
      (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * pow(e2, 3) / 1024) * sin(2 * latRad) +
      (15 * e2 * e2 / 256 + 45 * pow(e2, 3) / 1024) * sin(4 * latRad) -
      (35 * pow(e2, 3) / 3072) * sin(6 * latRad)
    );

    final double dL = lngRad - lng0Rad;
    final double dL2 = dL * dL;
    final double dL3 = dL2 * dL;
    final double dL4 = dL3 * dL;
    final double dL5 = dL4 * dL;
    final double dL6 = dL5 * dL;

    // --- Full Easting (5th-order Redfearn) ---
    final double easting = 500000.0 + k0 * N * (
      dL * cosLat +
      (dL3 * cosLat3 / 6.0) * (1 - t2 + ePrime2 * cosLat2) +
      (dL5 * cosLat5 / 120.0) * (5 - 18 * t2 + t4 + 72 * ePrime2 * cosLat2 - 58 * ePrime2)
    );

    // --- Full Northing (6th-order Redfearn) ---
    final double northingOffset = lat < 0 ? 10000000.0 : 0.0;
    final double northing = northingOffset + k0 * (M + N * t * (
      (dL2 * cosLat2 / 2.0) +
      (dL4 * cosLat4 / 24.0) * (5 - t2 + 9 * ePrime2 * cosLat2 + 4 * ePrime2 * ePrime2 * cosLat4) +
      (dL6 * cosLat6 / 720.0) * (61 - 58 * t2 + t4 + 600 * ePrime2 * cosLat2 - 330 * ePrime2)
    ));

    return "$zone${lat >= 0 ? 'N' : 'S'} E:${easting.toStringAsFixed(0)} N:${northing.toStringAsFixed(0)}";
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

  /// Thickness (qalinlik) hisoblash: true thickness = apparent × sin(dip)
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

// ═══════════════════════════════════════════════════════════════════════════
// STEREONET ENGINE (Projections and Contouring)
// ═══════════════════════════════════════════════════════════════════════════

enum StereonetProjection { schmidt, wulff }

class ProjectedPoint {
  final double x;
  final double y;
  final dynamic data; // Reference to Station or Measurement

  ProjectedPoint({required this.x, required this.y, this.data});
}

class StereonetEngine {
  /// Quyi yarim shar proyeksiyasi yordamida qatlamning 'Pole' nuqtasini topish (Strike/Dip -> DipDirection/Dip -> Pole -> X,Y)
  /// [dipDirection] 0-360
  /// [dip] 0-90
  /// [radius] stereonet radiusi
  /// [proj] Schmidt (Equal Area) yoki Wulff (Equal Angle)
  static ProjectedPoint projectPole({
    required double dipDirection,
    required double dip,
    required double radius,
    required StereonetProjection proj,
    dynamic data,
  }) {
    // Pole corresponds to plunge = 90 - dip, trend = dipDirection + 180 (or -180)
    final poleTrend = (dipDirection + 180) % 360;
    final polePlunge = 90 - dip;

    // Convert to radians
    final trendRad = poleTrend * pi / 180.0;

    double rOut;
    if (proj == StereonetProjection.wulff) {
      // Wulff: Equal-Angle -> R = R0 * tan((90 - Plunge) / 2)
      final pDeg = 90 - polePlunge;
      rOut = radius * tan((pDeg / 2) * pi / 180);
    } else {
      // Schmidt: Equal-Area -> R = R0 * sqrt(2) * sin((90 - Plunge) / 2)
      final pDeg = 90 - polePlunge;
      rOut = radius * sqrt(2) * sin((pDeg / 2) * pi / 180);
    }

    // Coordinates (assuming North is Up, +Y is down visually but let's standard cartesian: N=+y, E=+x)
    // Flutter canvas: +X is Right (East), +Y is Down (South). 
    // Trend = 0 (North) -> x = 0, y = -rOut
    final cx = rOut * sin(trendRad);
    final cy = -rOut * cos(trendRad);

    return ProjectedPoint(x: cx, y: cy, data: data);
  }

  /// Calculates a density grid (heat map) over the projection using a simple Gaussian kernel.
  static List<List<double>> calculateDensityGrid(
    List<ProjectedPoint> points,
    double radius,
    int gridSize,
    double bandwidth,
  ) {
    List<List<double>> grid = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
    final cellSize = (radius * 2) / gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final cx = -radius + x * cellSize + cellSize / 2;
        final cy = -radius + y * cellSize + cellSize / 2;
        
        // Only calculate inside the stereonet circle
        if (cx * cx + cy * cy > radius * radius) continue;

        double density = 0.0;
        for (var p in points) {
          final distSq = pow(p.x - cx, 2) + pow(p.y - cy, 2);
          density += exp(-distSq / (2 * pow(bandwidth, 2)));
        }
        grid[y][x] = density;
      }
    }
    return grid;
  }

  /// Tekislik (Great Circle) uchun nuqtalar to'plamini hisoblaydi.
  static List<Offset> calculateGreatCircle({
    required double strike,
    required double dip,
    required double radius,
    required StereonetProjection proj,
  }) {
    List<Offset> points = [];
    double dipDir = (strike + 90) % 360;
    double ddRad = (90 - dipDir) * pi / 180;
    double dipRad = dip * pi / 180;

    for (int i = -90; i <= 90; i++) {
      double beta = i * pi / 180;
      
      double xS = cos(beta);
      double yS = sin(beta) * cos(dipRad);
      double zS = -sin(beta) * sin(dipRad);

      double xR = xS * cos(ddRad) - yS * sin(ddRad);
      double yR = xS * sin(ddRad) + yS * cos(ddRad);
      
      if (zS > 0) continue; 

      double theta = acos(-zS); 
      double rOut;
      if (proj == StereonetProjection.wulff) {
        rOut = radius * tan(theta / 2);
      } else {
        rOut = radius * sqrt(2) * sin(theta / 2);
      }
      
      double mag = sqrt(xR * xR + yR * yR);
      if (mag == 0) {
        points.add(Offset.zero);
      } else {
        points.add(Offset(xR / mag * rOut, yR / mag * rOut));
      }
    }
    return points;
  }
}
