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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.sos, color: Colors.white, size: 28),
            Text(context.loc('hold'), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
