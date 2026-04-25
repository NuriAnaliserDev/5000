import 'package:firebase_auth/firebase_auth.dart';
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
    if (FirebaseAuth.instance.currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locRead('sos_login_required')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final settings = context.read<SettingsController>();
    final sos = context.read<SosService>();
    final loc = context.read<LocationService>();
    final name = settings.currentUserName ?? 'Geolog';

    HapticFeedback.heavyImpact();
    await loc.refreshLocation();
    Position? pos = loc.currentPosition;
    pos ??= await Geolocator.getLastKnownPosition();
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
                final ok =
                    await context.read<SosService>().cancelMyActiveSos();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? context.locRead('sos_cancelled')
                          : context.locRead('sos_cancel_failed'),
                    ),
                    backgroundColor: ok ? null : Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
        if (context.watch<SosService>().lastSendQueued) ...[
          const SizedBox(height: 4),
          Material(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                await context.read<SosService>().clearQueuedSignals();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.locRead('sos_queue_cleared')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  context.locRead('sos_queue_cancel'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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
