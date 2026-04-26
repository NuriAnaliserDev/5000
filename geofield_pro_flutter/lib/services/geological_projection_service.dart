import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../utils/geo/geo_constants.dart';
import '../utils/geology_utils.dart';

class ProjectedTrace {
  final List<LatLng> points;
  final double depth;
  final int stationId;

  ProjectedTrace({required this.points, required this.depth, required this.stationId});
}

class GeologicalProjectionService {
  /// Projects a geological contact trace at a hypothetical depth.
  /// [depthMeters] - depth below surface (negative for above).
  /// Uses basic trigonometric projection based on dip and strike.
  static List<LatLng> projectStation(Station station, double depthMeters) {
    if (station.dip == 0) return []; // Horizontal layer doesn't 'move' horizontally with depth (it's everywhere)
    
    // Dip Direction (azimuth of strongest descent)
    final double dipDir = GeologyUtils.calculateDipDirection(station.strike);
    
    // Horizontal shift distance: shift = depth / tan(dip)
    final double dipRad = station.dip * math.pi / 180;
    final double horizontalShift = depthMeters / math.tan(dipRad);
    
    // Calculate new center point
    final shiftedCenter = _movePoint(LatLng(station.lat, station.lng), dipDir, horizontalShift);
    
    // The trace is a line passing through shiftedCenter, parallel to Strike
    final double strike = station.strike;
    
    // Create a 500m long line segment for visualization
    const double halfLen = 250.0;
    final p1 = _movePoint(shiftedCenter, strike, halfLen);
    final p2 = _movePoint(shiftedCenter, (strike + 180) % 360, halfLen);
    
    return [p1, p2];
  }

  /// Moves a LatLng point by a certain distance in a specific azimuth.
  ///
  /// Uses WGS84 semi-major axis for consistency with UTM and other
  /// geodesic computations across the app.
  static LatLng _movePoint(LatLng start, double azimuthDeg, double distanceMeters) {
    const double earthRadius = GeoConstants.wgs84A;
    final double azRad = azimuthDeg * math.pi / 180;
    
    final double lat1 = start.latitude * math.pi / 180;
    final double lon1 = start.longitude * math.pi / 180;
    
    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceMeters / earthRadius) +
      math.cos(lat1) * math.sin(distanceMeters / earthRadius) * math.cos(azRad)
    );
    
    final double lon2 = lon1 + math.atan2(
      math.sin(azRad) * math.sin(distanceMeters / earthRadius) * math.cos(lat1),
      math.cos(distanceMeters / earthRadius) - math.sin(lat1) * math.sin(lat2)
    );
    
    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }
}
