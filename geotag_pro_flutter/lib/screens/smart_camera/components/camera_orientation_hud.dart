import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_card.dart';
import '../../../utils/status_semantics.dart';

class CameraOrientationHud extends StatelessWidget {
  final double strike;
  final double dip;
  final double declination;
  final int compassQuality;
  final bool isDark;
  final Color glassBorder;
  final Color textColor;
  final VoidCallback onShowCalibration;

  const CameraOrientationHud({
    super.key,
    required this.strike,
    required this.dip,
    required this.declination,
    required this.compassQuality,
    required this.isDark,
    required this.glassBorder,
    required this.textColor,
    required this.onShowCalibration,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 12,
      child: AppCard(
        opacity: 0.45,
        blur: 15,
        borderRadius: 14,
        padding: const EdgeInsets.all(10),
        baseColor: isDark ? Colors.black : Colors.white,
        border: Border.all(color: glassBorder, width: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onShowCalibration,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: (compassQuality < 40
                          ? StatusSemantics.colorFor(StatusLevel.danger)
                          : StatusSemantics.colorFor(StatusLevel.warn))
                      .withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      compassQuality < 40
                          ? Icons.warning_amber
                          : Icons.help_outline,
                      color: Colors.white,
                      size: 12),
                  const SizedBox(width: 4),
                  Text(
                      compassQuality < 40
                          ? 'KOMPAS SIFATI: $compassQuality%'
                          : context.loc('compass_calibration').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900))
                ]),
              ),
            ),
            if (compassQuality < 40)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  context.locRead('measurement_error_high'),
                  style: TextStyle(
                    color: StatusSemantics.colorFor(StatusLevel.danger),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
                '${context.locRead('strike_label')}: ${strike.toStringAsFixed(0)}°',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1976D2),
                    fontFeatures: [FontFeature.tabularFigures()])),
            Text('${context.locRead('dip_label')}: ${dip.toStringAsFixed(0)}°',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1976D2),
                    fontFeatures: [FontFeature.tabularFigures()])),
            if (declination != 0)
              Text(
                '${context.locRead('mag_decl_short')}: ${declination > 0 ? '+' : ''}${declination.toStringAsFixed(1)}°',
                style: TextStyle(
                    fontSize: 8,
                    color: textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
