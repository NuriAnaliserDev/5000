import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import 'geo/geo_constants.dart';

class ThreeDMathUtils {
  /// Project a GPS point to a local 3D space relative to a center point.
  /// Result is (x, y, z) in meters. Uses WGS84 semi-major axis for
  /// geodesic accuracy (previously used mean radius which gave ~0.1% bias).
  static Offset3D projectToLocal(LatLng point, double altitude, LatLng center, double centerAlt) {
    const double earthRadius = GeoConstants.wgs84A;

    final double latRad = point.latitude * pi / 180;
    final double lngRad = point.longitude * pi / 180;
    final double centerLatRad = center.latitude * pi / 180;
    final double centerLngRad = center.longitude * pi / 180;

    // Approximated local tangent plane projection
    final double x = (lngRad - centerLngRad) * cos(centerLatRad) * earthRadius;
    final double y = (latRad - centerLatRad) * earthRadius;
    final double z = altitude - centerAlt;

    return Offset3D(x, y, z);
  }

  /// Calculates the 4 corner points of a plane representing Strike and Dip.
  /// Strike: Clockwise from North (0-360)
  /// Dip: Angle from horizontal (0-90)
  /// Size: Length of the square side in meters
  static List<Offset3D> getStrikeDipPlane(Offset3D center, double strike, double dip, double size) {
    final double sRad = strike * pi / 180;
    final double dRad = dip * pi / 180;

    final double halfSize = size / 2;

    // Points in "Plane Local Space" (before rotation)
    // X is Strike direction, Y is Down-dip direction
    final List<Offset3D> localPoints = [
      Offset3D(-halfSize, -halfSize, 0),
      Offset3D(halfSize, -halfSize, 0),
      Offset3D(halfSize, halfSize, 0),
      Offset3D(-halfSize, halfSize, 0),
    ];

    // Rotation matrices
    // 1. Rotate by Dip around Strike axis (X)
    // 2. Rotate by Strike around Vertical axis (Z)
    return localPoints.map((p) {
      // Rotate by Dip (Around X axis)
      double y1 = p.y * cos(dRad) - p.z * sin(dRad);
      double z1 = p.y * sin(dRad) + p.z * cos(dRad);
      double x1 = p.x;

      // Rotate by Strike (Around Z axis)
      // Note: Strike is from North, so we adjust accordingly
      double x2 = x1 * cos(sRad) + y1 * sin(sRad);
      double y2 = -x1 * sin(sRad) + y1 * cos(sRad);
      double z2 = z1;

      return Offset3D(center.x + x2, center.y + y2, center.z + z2);
    }).toList();
  }

  /// Project a 3D point to 2D screen coordinates based on view matrix
  static Offset projectToScreen(Offset3D p, Matrix4 viewMatrix, Size screenSize) {
    vmath.Vector4 v = vmath.Vector4(p.x, p.y, p.z, 1.0);
    vmath.Vector4 vTransformed = viewMatrix.transform(v);
    
    // Simple perspective projection divide
    if (vTransformed.w == 0) return Offset.zero;
    
    double x = vTransformed.x / vTransformed.w;
    double y = vTransformed.y / vTransformed.w;

    return Offset(
      (x + 1) * screenSize.width / 2,
      (1 - y) * screenSize.height / 2,
    );
  }
}

class Offset3D {
  final double x, y, z;
  Offset3D(this.x, this.y, this.z);
}
