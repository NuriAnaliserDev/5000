import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';

class CameraHeadingHud extends StatelessWidget {
  final double azimuth;
  final Color glassColor;
  final Color glassBorder;
  final Color textColor;

  const CameraHeadingHud({
    super.key,
    required this.azimuth,
    required this.glassColor,
    required this.glassBorder,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 160, left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.6), width: 2),
              ),
              child: Center(
                child: Text('N', style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc('azimuth_label').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  azimuth.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1976D2)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
