import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Xarita o‘lchovlari: masofa, initial bearing, uch nuqta burchagi.
class MapGeodesy {
  MapGeodesy._();

  static const Distance _d = Distance();

  static double distanceMeters(LatLng a, LatLng b) {
    return _d.as(LengthUnit.Meter, a, b);
  }

  /// 0..360, shimoldan: A dan B gacha
  static double bearingDeg(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dL = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dL) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dL);
    final br = math.atan2(y, x) * 180 / math.pi;
    return (br + 360) % 360;
  }

  /// A–B–C burchagini B da (0..180)
  static double angleAtB(LatLng a, LatLng b, LatLng c) {
    final b1 = bearingDeg(b, a);
    final b2 = bearingDeg(b, c);
    var d = (b2 - b1 + 360) % 360;
    if (d > 180) d = 360 - d;
    return d;
  }

  static double chainLengthMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    var s = 0.0;
    for (var i = 1; i < pts.length; i++) {
      s += distanceMeters(pts[i - 1], pts[i]);
    }
    return s;
  }
}
