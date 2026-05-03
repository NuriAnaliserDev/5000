import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../services/sos_service.dart';
import 'pulse_marker.dart';
import '../../../core/error/error_handler.dart';

class MapSosSignalsLayer extends StatelessWidget {
  const MapSosSignalsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EmergencySignal>>(
      stream: context.read<SosService>().emergencySignals,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          ErrorHandler.process(snapshot.error!);
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        return MarkerLayer(
          markers: snapshot.data!.map((sig) {
            return Marker(
              point: sig.position,
              width: 100,
              height: 100,
              child: PulseMarker(name: sig.senderName),
            );
          }).toList(),
        );
      },
    );
  }
}
