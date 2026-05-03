import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'geo/geo_constants.dart';

/// WGS-84 / UTM (metr) — soddalashtirilgan, dala o‘lchovlari uchun.
/// 1–2 m atrofida; global geodetic ilovalarda PROJ/RTK tavsiya etiladi.
class UtmWgs84 {
  UtmWgs84._();

  static int zoneFromLongitude(double lon) {
    var z = ((lon + 180) / 6).floor() + 1;
    if (z < 1) z = 1;
    if (z > 60) z = 60;
    return z;
  }

  static String bandLetter(double lat) {
    const bands = 'CDEFGHJKLMNPQRSTUVWXX';
    if (lat >= 84) return 'X';
    if (lat < -80) return 'C';
    final i = (lat + 80) / 8;
    return bands[math.min(i.floor(), 19)];
  }

  /// UTM: zona, band, sharqiy (E) va shimoliy (N) nordonlar, metr.
  static ({int zone, String band, double easting, double northing}) toUtm(
    LatLng p,
  ) {
    const a = GeoConstants.wgs84A;
    const f = GeoConstants.wgs84F;
    final e2 = 2 * f - f * f;
    final e4 = e2 * e2;
    final e6 = e4 * e2;
    final ep2 = e2 / (1 - e2);
    final lat = p.latitude * math.pi / 180;
    final lon = p.longitude * math.pi / 180;
    final zone = zoneFromLongitude(p.longitude);
    final lon0 = ((zone - 1) * 6 - 180 + 3) * math.pi / 180;
    final k0 = 0.9996;
    final n = a / math.sqrt(1 - e2 * math.sin(lat) * math.sin(lat));
    final t = math.tan(lat) * math.tan(lat);
    final c = ep2 * math.cos(lat) * math.cos(lat);
    final m = a * ((1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * lat -
        (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * math.sin(2 * lat) +
        (15 * e4 / 256 + 45 * e6 / 1024) * math.sin(4 * lat) -
        (35 * e6 / 3072) * math.sin(6 * lat));
    final dlon = lon - lon0;
    final d2 = dlon * dlon;
    final d3 = d2 * dlon;
    final d4 = d3 * dlon;
    final d5 = d4 * dlon;
    final d6 = d5 * dlon;
    var x = k0 * n * (dlon * math.cos(lat) +
        (1 - t + c) * d3 * math.pow(math.cos(lat), 3) / 6 +
        (5 - 18 * t + t * t + 72 * c - 58 * ep2) *
            d5 * math.pow(math.cos(lat), 5) / 120);
    var y = k0 * (m + n * math.tan(lat) * (d2 * math.cos(lat) * math.cos(lat) / 2 +
        (5 - t + 9 * c + 4 * c * c) * d4 * math.pow(math.cos(lat), 4) / 24 +
        (61 - 58 * t + t * t + 600 * c - 330 * ep2) *
            d6 * math.pow(math.cos(lat), 6) / 720));
    x = x + 500000;
    if (p.latitude < 0) {
      y += 10000000; // South hemisphere
    }
    return (
      zone: zone,
      band: bandLetter(p.latitude),
      easting: x,
      northing: y,
    );
  }

  static String formatUtm(LatLng p) {
    final u = toUtm(p);
    return 'UTM Z${u.zone}${u.band} E${u.easting.toStringAsFixed(0)} N${u.northing.toStringAsFixed(0)}';
  }
}
