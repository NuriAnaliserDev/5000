import 'package:flutter/material.dart';
import 'package:geofield_pro_flutter/utils/app_localizations.dart';
import 'package:geofield_pro_flutter/utils/geo_orientation.dart';
import 'package:geofield_pro_flutter/utils/geological_plane_projector.dart';

import 'geology_stereonet_painter.dart';

/// Geologik kamera Focus Mode — stereonet + sun’iy gorizont (pitch/roll) + gravitatsiya proyeksiyasi.
class FocusModeGeologyOverlay extends StatelessWidget {
  final double pitch;
  final double roll;
  final double strike;
  final double dip;
  final double azimuth;
  final Vec3? gravity;
  final bool isDark;

  const FocusModeGeologyOverlay({
    super.key,
    required this.pitch,
    required this.roll,
    required this.strike,
    required this.dip,
    required this.azimuth,
    required this.gravity,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = GeoOrientationResult(
      // HUD geometriyasi: declination bu yerda 0 — stereonet/strike/azimuth allaqachon
      // smart kamerada calculateGeologicalOrientation (WMM) dan keyin true north.
      azimuth: azimuth,
      dip: dip,
      strike: strike,
      declination: 0,
      pitch: pitch,
      roll: roll,
    );
    final geom = computeFocusModeGeometry(
      orientation: orientation,
      gravity: gravity,
    );

    final bool isLevel = pitch.abs() < 2.0 && roll.abs() < 2.0;
    final color =
        isLevel ? Colors.greenAccent : (isDark ? Colors.white : Colors.black);
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        const double instrumentY = 0.34;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: StereonetOverlayLayer(
                  data: StereonetPlaneData(
                    strikeDeg: strike,
                    dipDeg: dip,
                    azimuthDeg: azimuth,
                  ),
                  motion: geom,
                  centerYFactor: instrumentY,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * instrumentY - 18,
              height: 36,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 26, height: 1.2, color: Colors.white24),
                    Container(width: 1.2, height: 26, color: Colors.white24),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        color: isLevel
                            ? color.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLevel)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${context.locRead('horizon_level')} ✓',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
