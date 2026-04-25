import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../services/sos_service.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

class MapSosButton extends StatelessWidget {
  final LatLng currentCenter;
  const MapSosButton({super.key, required this.currentCenter});

  void _triggerSos(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final sos = context.read<SosService>();
    final name = settings.currentUserName ?? 'Geolog';
    
    HapticFeedback.heavyImpact();
    await sos.sendSos(currentCenter, name);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc('sos_sent')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _triggerSos(context),
      child: Container(
        width: 56,
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
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
    );
  }
}
