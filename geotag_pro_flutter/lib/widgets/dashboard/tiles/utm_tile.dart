import 'package:flutter/material.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

/// UTM va aniqlik — [Selector] orqali faqat lat/lng/accuracy o'zgaganda qayta quriladi.
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_3x3_rounded, size: 14, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                context.loc('utm_coordinates'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          SelectableText(
            utm,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const Spacer(),
          Text(
            '${context.loc('acc_label')}: ${accuracyMeters.toStringAsFixed(1)}m | Lat: ${latitude.toStringAsFixed(6)}°, Lng: ${longitude.toStringAsFixed(6)}°',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
