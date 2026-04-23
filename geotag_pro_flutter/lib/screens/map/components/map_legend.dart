import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';
import '../../../models/station.dart';

class MapLegend extends StatelessWidget {
  final List<Station> stations;
  final Position? currentPos;
  final MapController mapController;

  const MapLegend({
    super.key,
    required this.stations,
    required this.currentPos,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      bottom: 96,
      child: AppCard(
        opacity: 0.45,
        blur: 10,
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        baseColor: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (stations.isEmpty) return;
                final points = stations.map((s) => LatLng(s.lat, s.lng)).toList();
                if (points.isEmpty) return;
                final bounds = LatLngBounds.fromPoints(points);
                mapController.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 10, color: Color(0xFF1976D2)),
                  const SizedBox(width: 6),
                  Text(
                    context.loc('active_point_label').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                final pos = currentPos;
                if (pos == null) return;
                mapController.move(
                  LatLng(pos.latitude, pos.longitude),
                  14,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    context.loc('observation_area_label').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
