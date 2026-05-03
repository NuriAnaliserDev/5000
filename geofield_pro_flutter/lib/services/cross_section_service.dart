import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';

class CrossSectionData {
  final Station station;
  final double distanceAlongProfile; // meters from start of section
  final double
      projectedDepth; // calculated based on apparent dip and distance if depth projection is used
  final double apparentDip; // degrees
  final double offsetFromProfile; // how far from the line (buffer distance)

  CrossSectionData({
    required this.station,
    required this.distanceAlongProfile,
    required this.projectedDepth,
    required this.apparentDip,
    required this.offsetFromProfile,
  });
}

class CrossSectionService {
  final Distance _distance = const Distance();

  /// Projects a list of stations onto a cross-section line defined by start and end points.
  /// [bufferMeters] determines how far to look sideways for data.
  List<CrossSectionData> generateProfile({
    required LatLng start,
    required LatLng end,
    required List<Station> stations,
    double bufferMeters = 500.0,
  }) {
    final List<CrossSectionData> results = [];
    final double sectionBearing = _distance.bearing(start, end);
    final double sectionLength = _distance.as(LengthUnit.Meter, start, end);

    for (var station in stations) {
      final LatLng stationPos = LatLng(station.lat, station.lng);

      // 1. Calculate the projection of station onto the infinite line A-B
      // Simplified approach: Distance from start and cross-track distance
      final double distFromStart =
          _distance.as(LengthUnit.Meter, start, stationPos);
      final double bearingFromStart = _distance.bearing(start, stationPos);

      // Relative angle between profile direction and station direction
      final double angleRad = (bearingFromStart - sectionBearing) * pi / 180.0;

      final double alongProfile = distFromStart * cos(angleRad);
      final double crossProfile = (distFromStart * sin(angleRad)).abs();

      // 2. Filter by buffer and section bounds
      if (crossProfile > bufferMeters) continue;
      if (alongProfile < 0 || alongProfile > sectionLength) continue;

      // 3. Calculate Apparent Dip
      // Beta is angle between strike and section line
      final double strike = station.strike;
      double beta = (strike - sectionBearing).abs() % 180;
      if (beta > 90) beta = 180 - beta;

      // True Dip
      final double alpha = station.dip;

      // tan(alpha') = tan(alpha) * sin(beta)
      // Note: This assumes profile is perpendicular to strike for beta=90
      final double apparentDipRad =
          atan(tan(alpha * pi / 180.0) * sin(beta * pi / 180.0));
      final double apparentDip = apparentDipRad * 180.0 / pi;

      results.add(CrossSectionData(
        station: station,
        distanceAlongProfile: alongProfile,
        projectedDepth: station.altitude, // Initial Y is the elevation
        apparentDip: apparentDip,
        offsetFromProfile: crossProfile,
      ));
    }

    // Sort by distance for easier rendering/labeling
    results.sort(
        (a, b) => a.distanceAlongProfile.compareTo(b.distanceAlongProfile));
    return results;
  }
}
