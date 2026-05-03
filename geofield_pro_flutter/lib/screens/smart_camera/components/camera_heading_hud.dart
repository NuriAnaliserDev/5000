import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/location_service.dart';
import '../../../utils/app_localizations.dart';

class CameraHeadingHud extends StatelessWidget {
  final double azimuth;
  final Color glassColor;
  final Color glassBorder;
  final Color textColor;

  /// Pastki navigatsiya va boshqaruv ustidan bo‘sh joy (masalan `overlayClearanceAboveNav + 140`).
  final double bottomInset;

  const CameraHeadingHud({
    super.key,
    required this.azimuth,
    required this.glassColor,
    required this.glassBorder,
    required this.textColor,
    this.bottomInset = 168,
  });

  static String _cardinal(double deg) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((deg + 22.5) / 45).floor() % 8;
    return labels[i];
  }

  @override
  Widget build(BuildContext context) {
    final card = _cardinal(azimuth);
    final loc = context.watch<LocationService>().currentPosition;
    final acc = loc?.accuracy;

    return Positioned(
      bottom: bottomInset,
      left: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${context.loc('camera_azimuth_short')}: ${azimuth.toStringAsFixed(0)}° ($card)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.loc('camera_azimuth_subtitle'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: textColor.withValues(alpha: 0.78),
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  acc != null
                      ? '${context.loc('camera_heading_info_line')} · ±${acc.toStringAsFixed(1)} m'
                      : context.loc('camera_heading_info_line'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.88),
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
