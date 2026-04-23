import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class LineworkUtils {
  /// Subdivides a sequence of points into a smooth Bezier path.
  /// Uses Catmull-Rom spline interpolation if control points aren't explicitly provided,
  /// or Quadratic/Cubic Bezier logic if they are.
  static List<LatLng> smoothLine(List<LatLng> points, {int subdivisions = 8}) {
    if (points.length < 2) return points;
    
    final List<LatLng> result = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 >= points.length ? points[i + 1] : points[i + 2];
      
      for (int t = 0; t < subdivisions; t++) {
        final double ratio = t / subdivisions;
        result.add(_catmullRom(p0, p1, p2, p3, ratio));
      }
    }
    
    result.add(points.last);
    return result;
  }

  /// Standard Catmull-Rom Spline interpolation
  static LatLng _catmullRom(LatLng p0, LatLng p1, LatLng p2, LatLng p3, double t) {
    final double t2 = t * t;
    final double t3 = t2 * t;

    final double lat = 0.5 * (
      (2 * p1.latitude) +
      (-p0.latitude + p2.latitude) * t +
      (2 * p0.latitude - 5 * p1.latitude + 4 * p2.latitude - p3.latitude) * t2 +
      (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3
    );

    final double lng = 0.5 * (
      (2 * p1.longitude) +
      (-p0.longitude + p2.longitude) * t +
      (2 * p0.longitude - 5 * p1.longitude + 4 * p2.longitude - p3.longitude) * t2 +
      (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) * t3
    );

    return LatLng(lat, lng);
  }

  /// Calculates points for complex structural symbols (e.g. thrust teeth)
  /// Returns a list of coordinates for the 'teeth' triangles along the line.
  static List<List<LatLng>> calculateThrustTeeth(List<LatLng> points, {double sizeMeters = 50}) {
    // This is more complex since we need to work in projected space (meters)
    // For now, simpler version using degrees as proxy
    final List<List<LatLng>> teeth = [];
    const double degSize = 0.0005; // approx 50m
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      // Midpoint
      final midLat = (p1.latitude + p2.latitude) / 2;
      final midLng = (p1.longitude + p2.longitude) / 2;
      
      // Normal vector (perpendicular to segments)
      final dLat = p2.latitude - p1.latitude;
      final dLng = p2.longitude - p1.longitude;
      final len = math.sqrt(dLat * dLat + dLng * dLng);
      if (len == 0) continue;
      
      final nLat = -dLng / len;
      final nLng = dLat / len;
      
      // Create triangle vertex
      final vLat = midLat + nLat * degSize;
      final vLng = midLng + nLng * degSize;
      
      teeth.add([
         LatLng(midLat + (dLat / len) * 0.0002, midLng + (dLng / len) * 0.0002),
         LatLng(vLat, vLng),
         LatLng(midLat - (dLat / len) * 0.0002, midLng - (dLng / len) * 0.0002),
      ]);
    }
    return teeth;
  }

  /// Eng yaqin stansiya yoki nuqtaga "yopishish" (snapping) nuqtasini topadi.
  static LatLng? findNearestSnapPoint(LatLng tapPoint, List<LatLng> candidates, {double thresholdDegrees = 0.0005}) {
    LatLng? nearest;
    double minDist = double.infinity;

    for (final p in candidates) {
      final dLat = p.latitude - tapPoint.latitude;
      final dLng = p.longitude - tapPoint.longitude;
      final dist = math.sqrt(dLat * dLat + dLng * dLng);

      if (dist < thresholdDegrees && dist < minDist) {
        minDist = dist;
        nearest = p;
      }
    }
    return nearest;
  }
}
