import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:geofield_pro_flutter/utils/app_localizations.dart';
import 'package:geofield_pro_flutter/utils/geology_utils.dart';

import 'geology_stereonet_painter.dart';

/// Geologik kamera Focus Mode — stereonet uslubidagi ikki tekislik + sensor raqamlari.
class FocusModeGeologyOverlay extends StatelessWidget {
  final double pitch;
  final double roll;
  final double strike;
  final double dip;
  final double azimuth;
  final bool isDark;

  const FocusModeGeologyOverlay({
    super.key,
    required this.pitch,
    required this.roll,
    required this.strike,
    required this.dip,
    required this.azimuth,
    this.isDark = true,
  });

  static String _bearing8(double deg) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((deg + 22.5) / 45).floor() % 8;
    return labels[i];
  }

  @override
  Widget build(BuildContext context) {
    final bool isLevel = pitch.abs() < 2.0 && roll.abs() < 2.0;
    final color =
        isLevel ? Colors.greenAccent : (isDark ? Colors.white : Colors.black);
    final dipDir = _bearing8(GeologyUtils.calculateDipDirection(strike));

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
            Positioned(
              left: 0,
              right: 0,
              top: h * instrumentY + 4,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 36,
                                margin: const EdgeInsets.only(right: 10, top: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${context.locRead('strike_label')}: ${strike.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 32,
                                margin: const EdgeInsets.only(right: 10, top: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF64B5F6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${context.locRead('dip_label')}: ${dip.toStringAsFixed(0)}° $dipDir',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.96),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.locRead('camera_plane_attitude_subtitle'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
