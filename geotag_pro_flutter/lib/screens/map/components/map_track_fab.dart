import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/track_service.dart';

class MapTrackFab extends StatelessWidget {
  const MapTrackFab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context)!;
    return Consumer<TrackService>(
      builder: (context, trackSvc, _) {
        final active = trackSvc.isTracking;
        return Semantics(
          label: s.map_track_fab_aria,
          button: true,
          child: Tooltip(
            message: s.map_track_fab_aria,
            child: FloatingActionButton(
              heroTag: 'map_track_fab',
              backgroundColor: active ? Colors.red.shade800 : const Color(0xFF1B5E20),
              onPressed: () async {
                if (active) {
                  await trackSvc.stopTracking();
                  return;
                }
                final name = 'Trek-${DateTime.now().toIso8601String().substring(0, 19)}'
                    .replaceAll(':', '.');
                await trackSvc.startTracking(name);
                if (!context.mounted) return;
                if (!trackSvc.isTracking) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.track_start_failed),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.tracking_started_snack),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Icon(
                active ? Icons.stop_rounded : Icons.fiber_manual_record,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
