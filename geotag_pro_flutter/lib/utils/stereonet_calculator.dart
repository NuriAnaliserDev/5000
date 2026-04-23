import 'dart:math' as math;
import 'package:flutter/material.dart';

class StereonetPoint {
  final double x;
  final double y;
  final String label;
  final Color? color;

  StereonetPoint(this.x, this.y, {this.label = '', this.color});
}

/// Schmidt (Equal-Area) Projection kalkulyatori.
/// Geologik Strike/Dip ma'lumotlarini 2D (x, y) koordinatalariga o'tkazadi.
class StereonetCalculator {
  static const double radius = 1.0;

  /// Strike/Dip'dan Pole (qutb) nuqtasini hisoblaydi.
  /// Strike: 0-360, Dip: 0-90
  /// Qoidaga ko'ra: Dip Direction = (Strike + 90) % 360
  static StereonetPoint calculatePole(double strike, double dip) {
    // 1. Dip Directionni aniqlaymiz
    double dipDir = (strike + 90) % 360;
    
    // 2. Qutbning Azimutini hisoblaymiz (Dip Directionning teskarisi)
    double poleAzimuth = (dipDir + 180) % 360;
    
    // 3. Dip'dan qutbning burchagini hisoblaymiz (90 - dip)
    // Schmidt Net formulasi: R = sqrt(2) * sin(theta/2)
    // Bu yerda theta = 90 - dip (zenith distance)
    double thetaRad = (90 - dip) * math.pi / 180;
    double r = math.sqrt(2) * math.sin(thetaRad / 2);
    
    // 4. Polar to Cartesian
    double azimuthRad = (90 - poleAzimuth) * math.pi / 180;
    double x = r * math.cos(azimuthRad);
    double y = r * math.sin(azimuthRad);

    return StereonetPoint(x, y);
  }

  /// Tekislik (Great Circle) uchun nuqtalar to'plamini hisoblaydi.
  static List<Offset> calculateGreatCircle(double strike, double dip) {
    List<Offset> points = [];
    double dipDir = (strike + 90) % 360;
    
    // Dip direction gradusdan radisanga
    double ddRad = (90 - dipDir) * math.pi / 180;
    double dipRad = dip * math.pi / 180;

    for (int i = -90; i <= 90; i++) {
      double beta = i * math.pi / 180;
      
      // Spherical to Cartesian on sphere
      double xS = math.cos(beta);
      double yS = math.sin(beta) * math.cos(dipRad);
      double zS = -math.sin(beta) * math.sin(dipRad);

      // Rotate by Dip Direction
      double xR = xS * math.cos(ddRad) - yS * math.sin(ddRad);
      double yR = xS * math.sin(ddRad) + yS * math.cos(ddRad);
      
      // Schmidt projection from sphere to plane
      // theta - zenith angle (angle from vertical Z axis)
      // We need to normalize to lower hemisphere (z < 0)
      if (zS > 0) continue; 

      // Distance from center
      double theta = math.acos(-zS); // Angle from -Z axis
      double r = math.sqrt(2) * math.sin(theta / 2);
      
      // Projected coordinates
      double mag = math.sqrt(xR * xR + yR * yR);
      if (mag == 0) {
        points.add(Offset.zero);
      } else {
        points.add(Offset(xR / mag * r, yR / mag * r));
      }
    }
    return points;
  }
}
