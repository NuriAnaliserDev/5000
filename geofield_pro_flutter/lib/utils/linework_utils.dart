import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/boundary_polygon.dart';
import '../models/geological_line.dart';

class LineworkUtils {
  static const Distance _distance = Distance();

  /// Chiziladigan (render) nuqtalar — silliqlangan yoki asl to‘g‘ri chiziq.
  static List<LatLng> renderedPoints(GeologicalLine l) {
    if (l.lats.isEmpty) return [];
    var pts = List.generate(l.lats.length, (i) => LatLng(l.lats[i], l.lngs[i]));
    if (l.isCurved && pts.length >= 2) {
      pts = smoothLine(pts);
    }
    return pts;
  }

  /// Yopiq poligon: nuqta shakl ichidami (xarita poligon chizgisi bilan mos, silliqsiz to‘g‘rilar).
  static bool polygonContainsPoint(LatLng point, List<LatLng> ring) {
    if (ring.length < 3) return false;
    final lat = point.latitude;
    final lng = point.longitude;
    int winding = 0;
    for (int i = 0; i < ring.length; i++) {
      final p1 = ring[i];
      final p2 = ring[(i + 1) % ring.length];
      final lat1 = p1.latitude, lng1 = p1.longitude;
      final lat2 = p2.latitude, lng2 = p2.longitude;
      if (lat1 <= lat) {
        if (lat2 > lat) {
          if (_isLeft2(lng1, lat1, lng2, lat2, lng, lat) > 0) winding++;
        }
      } else {
        if (lat2 <= lat) {
          if (_isLeft2(lng1, lat1, lng2, lat2, lng, lat) < 0) winding--;
        }
      }
    }
    return winding != 0;
  }

  static double _isLeft2(
    double x1, double y1,
    double x2, double y2,
    double px, double py,
  ) {
    return (x2 - x1) * (py - y1) - (px - x1) * (y2 - y1);
  }

  static LatLng _closestOnSegment(LatLng p, LatLng a, LatLng b) {
    final dLat = b.latitude - a.latitude;
    final dLng = b.longitude - a.longitude;
    final l2 = dLat * dLat + dLng * dLng;
    if (l2 < 1e-22) return a;
    var t = ((p.latitude - a.latitude) * dLat + (p.longitude - a.longitude) * dLng) / l2;
    t = t.clamp(0.0, 1.0);
    return LatLng(a.latitude + t * dLat, a.longitude + t * dLng);
  }

  /// Nuqta ochiq yoki yopiq poliliniya chegarasigacha (metr) eng yaqin masofa.
  static double _minDistanceToPolylineEdge(
    LatLng tap,
    List<LatLng> pts, {
    required bool closed,
  }) {
    if (pts.length < 2) return double.infinity;
    double best = double.infinity;
    final n = closed ? pts.length : pts.length - 1;
    for (int i = 0; i < n; i++) {
      final a = pts[i];
      final b = closed ? pts[(i + 1) % pts.length] : pts[i + 1];
      final c = _closestOnSegment(tap, a, b);
      final d = _distance.as(LengthUnit.Meter, tap, c);
      if (d < best) best = d;
    }
    return best;
  }

  /// `tap` nuqtasining ushbu geologik chiziqgacha eng kam masofasi (metr).
  static double minDistanceMetersToLine(LatLng tap, GeologicalLine l) {
    if (l.lats.isEmpty) return double.infinity;
    final raw = List.generate(l.lats.length, (i) => LatLng(l.lats[i], l.lngs[i]));

    if (l.isClosed) {
      if (raw.length < 3) return double.infinity;
      if (polygonContainsPoint(tap, raw)) return 0.0;
      return _minDistanceToPolylineEdge(tap, raw, closed: true);
    }
    if (raw.length < 2) return double.infinity;
    final pts = renderedPoints(l);
    if (pts.length < 2) return double.infinity;
    return _minDistanceToPolylineEdge(tap, pts, closed: false);
  }

  /// Xarita masshtabiga mos «bosish» radiusi: `tap` atrofida `maxDistanceMeters` ichida bo‘lgan chizma.
  static GeologicalLine? findGeologicalLineNear(
    LatLng tap,
    List<GeologicalLine> lines, {
    required double maxDistanceMeters,
  }) {
    GeologicalLine? best;
    var bestD = double.infinity;
    for (final l in lines) {
      final d = minDistanceMetersToLine(tap, l);
      if (d < bestD) {
        bestD = d;
        best = l;
      }
    }
    if (best != null && bestD <= maxDistanceMeters) return best;
    return null;
  }
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

  /// Ixtiyoriy metrli to‘r (WGS-84 taxmin) — fokus atrofida bitta yopishish nuqtasi.
  static LatLng nearestGridPoint(LatLng p, double gridMeters) {
    if (gridMeters <= 0) return p;
    const lat0 = 111320.0;
    final latRad = p.latitude * math.pi / 180.0;
    final mPerDegLng = lat0 * math.cos(latRad).clamp(0.02, 1.0);
    final gx = (p.longitude * mPerDegLng / gridMeters).round() * (gridMeters / mPerDegLng);
    final gy = (p.latitude * lat0 / gridMeters).round() * (gridMeters / lat0);
    return LatLng(gy, gx);
  }

  /// Stansiya, barcha chiziq/chegara vertikallari, ixtiyoriy panjaraga yaqin bitta nuqta.
  static List<LatLng> buildSnapCandidatePoints({
    required List<LatLng> stationPoints,
    required List<GeologicalLine> lines,
    required List<BoundaryPolygon> boundaries,
    required LatLng focus,
    int snapGridMeters = 0,
  }) {
    final out = <LatLng>[];
    out.addAll(stationPoints);
    for (final line in lines) {
      final n = line.lats.length;
      for (var i = 0; i < n; i++) {
        out.add(LatLng(line.lats[i], line.lngs[i]));
      }
    }
    for (final b in boundaries) {
      out.addAll(b.points);
    }
    if (snapGridMeters > 0) {
      out.add(nearestGridPoint(focus, snapGridMeters.toDouble()));
    }
    return out;
  }
}
