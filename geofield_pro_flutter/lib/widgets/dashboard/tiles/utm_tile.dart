import 'package:flutter/material.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

/// UTM, ACC yashil «pill» va lat/lng — Stitch xarita kartasiga yaqin.
class UTMTile extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isDark;

  const UTMTile({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final utm = GeologyUtils.toUTM(latitude, longitude);
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'UTM: $utm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${context.loc('acc_label')}: ${accuracyMeters.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lat: ${latitude.toStringAsFixed(6)}° | Lng: ${longitude.toStringAsFixed(6)}°',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
