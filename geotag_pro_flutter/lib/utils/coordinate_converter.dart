import 'dart:math';

class CoordinateConverter {
  /// Simple WGS84 to UTM conversion (Simplified for Zone 42N/43N - Central Asia)
  /// Note: For full accuracy in production, a library like 'proj4dart' is recommended.
  /// This is a robust approximation for display purposes.
  static Map<String, double> latLngToUtm(double lat, double lng) {
    const double a = 6378137.0; // WGS84 semi-major axis
    const double f = 1 / 298.257223563; // WGS84 flattening
    const double k0 = 0.9996; // UTM scale factor

    final int zoneNum = ((lng + 180) / 6).floor() + 1;
    final double lonOrigin = (zoneNum - 1) * 6 - 180 + 3;
    final double lonOriginRad = lonOrigin * pi / 180;

    final double e2 = 2 * f - f * f;
    final double ep2 = e2 / (1 - e2);

    final double latRad = lat * pi / 180;
    final double lonRad = lng * pi / 180;

    final double N = a / sqrt(1 - e2 * sin(latRad) * sin(latRad));
    final double T = tan(latRad) * tan(latRad);
    final double C = ep2 * cos(latRad) * cos(latRad);
    final double A = cos(latRad) * (lonRad - lonOriginRad);

    final double M = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * latRad -
        (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * sin(2 * latRad) +
        (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * sin(4 * latRad) -
        (35 * e2 * e2 * e2 / 3072) * sin(6 * latRad));

    final double easting = k0 * N * (A + (1 - T + C) * pow(A, 3) / 6 +
        (5 - 18 * T + T * T + 72 * C - 58 * ep2) * pow(A, 5) / 120) + 500000.0;

    double northing = k0 * (M + N * tan(latRad) * (A * A / 2 + (5 - T + 9 * C + 4 * C * C) * pow(A, 4) / 24 +
        (61 - 58 * T + T * T + 600 * C - 330 * ep2) * pow(A, 6) / 720));

    if (lat < 0) {
      northing += 10000000.0; // South hemisphere offset
    }

    return {
      'easting': easting,
      'northing': northing,
      'zone': zoneNum.toDouble(),
    };
  }

  static String formatUtm(double lat, double lng) {
    final utm = latLngToUtm(lat, lng);
    return "${utm['zone']?.toInt()}N  E: ${utm['easting']?.toStringAsFixed(0)}  N: ${utm['northing']?.toStringAsFixed(0)}";
  }
}
