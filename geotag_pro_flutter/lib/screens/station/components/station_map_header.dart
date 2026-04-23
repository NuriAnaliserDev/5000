import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/station.dart';

class StationMapHeader extends StatelessWidget {
  final Station? station;
  final String currentStyle;
  final FMTCTileProvider tileProvider;

  const StationMapHeader({
    super.key,
    required this.station,
    required this.currentStyle,
    required this.tileProvider,
  });

  String _getUrlTemplate(String style) {
    switch (style) {
      case 'osm':
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'opentopomap':
      default:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains(String style) {
    if (style == 'satellite') return const [];
    return const ['a', 'b', 'c'];
  }

  @override
  Widget build(BuildContext context) {
    final hasValidCoords = station != null && !(station!.lat == 0.0 && station!.lng == 0.0);
    final center = hasValidCoords ? LatLng(station!.lat, station!.lng) : const LatLng(41.2995, 69.2401);

    return SizedBox(
      height: 260,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: _getUrlTemplate(currentStyle),
            subdomains: _getSubdomains(currentStyle),
            userAgentPackageName: 'com.geofield.pro.flutter',
            maxNativeZoom: currentStyle == 'satellite' ? 17 : 15,
            maxZoom: 18,
            keepBuffer: 3,
            panBuffer: 1,
            tileProvider: tileProvider,
          ),
          if (station != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(station!.lat, station!.lng),
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.location_on,
                    size: 28,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
