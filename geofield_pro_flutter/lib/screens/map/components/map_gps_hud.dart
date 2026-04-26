import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/location_service.dart';

class MapGpsHud extends StatelessWidget {
  const MapGpsHud({super.key});

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final loc = locService.currentPosition;
    final status = locService.status;

    Color statusColor;
    String statusText;
    switch (status) {
      case GpsStatus.good:
        statusColor = Colors.green;
        statusText = 'GPS: ${loc?.accuracy.toStringAsFixed(1)} m';
        break;
      case GpsStatus.medium:
        statusColor = Colors.orange;
        statusText = 'GPS: ${loc?.accuracy.toStringAsFixed(1)} m';
        break;
      case GpsStatus.poor:
        statusColor = Colors.red;
        statusText = 'GPS: Past';
        break;
      case GpsStatus.searching:
        statusColor = Colors.orangeAccent;
        statusText = 'GPS...';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'GPS Off';
        break;
    }

    return Positioned(
      top: 140,
      left: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.satellite_alt, color: statusColor, size: 14),
            const SizedBox(width: 4),
            Text(statusText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
