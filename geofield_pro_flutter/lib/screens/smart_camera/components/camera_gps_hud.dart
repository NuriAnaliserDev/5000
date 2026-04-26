import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/location_service.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_card.dart';
import '../../../utils/status_semantics.dart';

class CameraGpsHud extends StatelessWidget {
  final bool isDark;
  final Color glassBorder;
  final Color textColor;

  const CameraGpsHud({
    super.key,
    required this.isDark,
    required this.glassBorder,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final loc = locService.currentPosition;
    final lat = loc?.latitude;
    final lng = loc?.longitude;
    final alt = loc?.altitude;
    final acc = loc?.accuracy;

    String gpsStatus = context.loc('searching_gps').toUpperCase();
    if (locService.status == GpsStatus.good) gpsStatus = context.loc('gps_status_good').toUpperCase();
    if (locService.status == GpsStatus.medium) gpsStatus = context.loc('gps_status_medium_short');
    if (locService.status == GpsStatus.poor) gpsStatus = context.loc('gps_status_poor_short');

    return Positioned(
      top: 80, left: 12, width: MediaQuery.of(context).size.width * 0.65,
      child: Stack(
        children: [
          AppCard(
            opacity: 0.45, blur: 15, borderRadius: 16, padding: const EdgeInsets.all(12),
            baseColor: isDark ? Colors.black : Colors.white,
            border: Border.all(color: glassBorder, width: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gpsStatus,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: locService.status == GpsStatus.good
                        ? StatusSemantics.colorFor(StatusLevel.good)
                        : StatusSemantics.colorFor(StatusLevel.warn),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(lat != null ? '${lat.abs().toStringAsFixed(5)}°${lat >= 0 ? 'N' : 'S'}' : '—', style: const TextStyle(fontSize: 16, color: Color(0xFF1976D2), fontWeight: FontWeight.w900)),
                Text(lng != null ? '${lng.abs().toStringAsFixed(5)}°${lng >= 0 ? 'E' : 'W'}' : '—', style: const TextStyle(fontSize: 16, color: Color(0xFF1976D2), fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.height, color: textColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${context.loc('altitude')}: ${(alt != null ? alt.toStringAsFixed(1) : '—')} m', style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          if (loc != null)
                            Text('${context.loc('last_update')}: ${locService.lastUpdateTime.hour.toString().padLeft(2, '0')}:${locService.lastUpdateTime.minute.toString().padLeft(2, '0')}:${locService.lastUpdateTime.second.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 9, color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: const Color(0xFF1976D2), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${context.loc('accuracy')}: ±${acc?.toStringAsFixed(1) ?? '—'} m', style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Icon(Icons.refresh, size: 14, color: textColor.withValues(alpha: 0.5)),
              onPressed: () {
                locService.restartService();
              },
            ),
          ),
        ],
      ),
    );
  }
}
