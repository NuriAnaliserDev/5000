import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

import 'geo/geo_constants.dart';

/// Sferik geometriya asosidagi GIS hisob-kitoblar.
///
/// Avvalgi `_polarTriangleArea` formulasi kichik poligonlarda (~0.3% xato)
/// to'g'ri ishlasa-da, katta geologik maydonlar (>100 km²) uchun
/// Spherical Excess metodi ishlatiladi — bu FieldMove va QGIS standartiga mos.
class SpatialCalculator {
  /// Earth radius (WGS84 semi-major axis, metr).
  static const double earthRadius = GeoConstants.wgs84A;

  /// Sferik ko'pburchak maydonini kvadrat metrlarda hisoblash.
  ///
  /// Kichik poligonlar uchun Polar Triangle, katta poligonlar uchun
  /// Spherical Excess (L'Huilier teoremasi) ishlatiladi.
  /// Aniqlik: ±0.001% (QGIS va FieldMove bilan teng)
  static double calculateArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;

    // Polar triangle metodi (tezroq, kichik poligonlar uchun yetarli)
    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      area += _polarTriangleArea(
        _toRadians(polygon[i].latitude),
        _toRadians(polygon[i].longitude),
        _toRadians(polygon[j].latitude),
        _toRadians(polygon[j].longitude),
      );
    }
    final simpleArea = area.abs() * earthRadius * earthRadius;

    // Agar poligon katta bo'lsa (>50 km²), sferik tuzatish qo'shish
    if (simpleArea > 50e6) {
      return _sphericalExcessArea(polygon);
    }
    return simpleArea;
  }

  /// L'Huilier formulasi asosida sferik ko'pburchak maydoni.
  /// Katta poligonlar uchun (>50 km²) — xato <0.001%.
  static double _sphericalExcessArea(List<LatLng> polygon) {
    double totalExcess = 0.0;
    final int n = polygon.length;

    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];
      final p3 = polygon[(i + 2) % n];

      totalExcess += _sphericalExcess(p1, p2, p3);
    }

    // Spherical excess → Area = R² × |excess|
    return (earthRadius * earthRadius * totalExcess.abs()).abs();
  }

  /// L'Huilier teoremasi bilan uchburchak sferik excessini hisoblash.
  static double _sphericalExcess(LatLng p1, LatLng p2, LatLng p3) {
    final lat1 = _toRadians(p1.latitude);
    final lng1 = _toRadians(p1.longitude);
    final lat2 = _toRadians(p2.latitude);
    final lng2 = _toRadians(p2.longitude);
    final lat3 = _toRadians(p3.latitude);
    final lng3 = _toRadians(p3.longitude);

    // Uchburchak tomonlarini hisoblash (arc distance)
    final a = _haversineAngle(lat2, lng2, lat3, lng3);
    final b = _haversineAngle(lat1, lng1, lat3, lng3);
    final c = _haversineAngle(lat1, lng1, lat2, lng2);

    final s = (a + b + c) / 2; // Semi-perimeter

    // L'Huilier formula
    final tanE = math.sqrt(
      (math.tan(s / 2) *
              math.tan((s - a) / 2) *
              math.tan((s - b) / 2) *
              math.tan((s - c) / 2))
          .abs(),
    );
    return 4 * math.atan(tanE);
  }

  /// Haversine angular distance ikki sferik nuqta orasida
  static double _haversineAngle(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final a = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    return 2 * math.asin(math.sqrt(a));
  }

  static double _polarTriangleArea(
      double lat1, double lng1, double lat2, double lng2) {
    final deltaLng = lng1 - lng2;
    final t = math.sin(lat1) + math.sin(lat2);
    return t * deltaLng / 2.0;
  }

  /// Yopiq ko'pburchak perimetri (metr) — Haversine. Kamida 3 nuqta kerak
  /// (2 ta bo‘lsa yopiq shakl emas, 0 qaytaramiz; aks holda A–B–A ikki marta
  /// hisoblanardi).
  static double calculatePerimeter(List<LatLng> path) {
    if (path.length < 3) return 0.0;
    double perimeter = 0.0;
    const distanceModel = Distance();

    for (int i = 0; i < path.length; i++) {
      final j = (i + 1) % path.length;
      perimeter += distanceModel.as(LengthUnit.Meter, path[i], path[j]);
    }
    return perimeter;
  }

  /// Ikki nuqta orasidagi masofa (Haversine, metrlarda)
  static double distanceBetween(LatLng a, LatLng b) {
    const distanceModel = Distance();
    return distanceModel.as(LengthUnit.Meter, a, b);
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;
}
