import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../services/sos_service.dart';
import '../../../services/settings_controller.dart';
import '../../../services/location_service.dart';
import '../../../utils/app_localizations.dart';

class MapSosButton extends StatelessWidget {
  const MapSosButton({super.key});

  Future<void> _resolveGpsAndSend(
    BuildContext context,
  ) async {
    final settings = context.read<SettingsController>();
    final sos = context.read<SosService>();
    final loc = context.read<LocationService>();
    final name = settings.currentUserName ?? 'Geolog';

    HapticFeedback.heavyImpact();
    await loc.refreshLocation();
    Position? pos = loc.currentPosition;
    if (pos == null) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locRead('sos_gps_unavailable')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }

    final point = LatLng(pos.latitude, pos.longitude);
    await sos.sendSos(point, name);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locRead('sos_sent')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosService>();
    final hasActive = sos.myActiveSosDocumentId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPress: () => _resolveGpsAndSend(context),
          child: Container(
            width: 56,
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: hasActive ? Colors.deepOrange : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (hasActive ? Colors.deepOrange : Colors.red)
                      .withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sos, color: Colors.white, size: 24),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.loc('hold'),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasActive) ...[
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await context.read<SosService>().cancelMyActiveSos();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.locRead('sos_cancelled')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  context.loc('sos_cancel'),
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
