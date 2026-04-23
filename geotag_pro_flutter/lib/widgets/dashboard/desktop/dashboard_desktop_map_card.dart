import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/station.dart';

class DashboardDesktopMapCard extends StatelessWidget {
  final List<Station> stations;

  const DashboardDesktopMapCard({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    final center = stations.isEmpty ? const LatLng(41.2995, 69.2401) : LatLng(stations.last.lat, stations.last.lng);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geofield.pro.flutter',
            ),
            MarkerLayer(
              markers: stations.map((s) => Marker(
                point: LatLng(s.lat, s.lng),
                width: 12,
                height: 12,
                child: Container(decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
              )).toList(),
            ),
            const Positioned(
              top: 10,
              left: 10,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text('Field Map View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
