import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/station.dart';
import '../../../utils/geological_symbols.dart';

class MapStationLayer extends StatelessWidget {
  final List<Station> stations;
  final Function(Station) onStationTap;

  const MapStationLayer({
    super.key,
    required this.stations,
    required this.onStationTap,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerClusterLayer(
      mapCamera: MapCamera.of(context),
      mapController: MapController.of(context),
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 40,
        size: const Size(40, 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(50),
        maxZoom: 15,
        markers: stations
            .map(
              (Station s) => Marker(
                width: 40,
                height: 40,
                point: LatLng(s.lat, s.lng),
                child: GestureDetector(
                  onTap: () => onStationTap(s),
                  child: GeologicalSymbolWidget(
                    measurementType: s.measurementType ?? 'bedding',
                    subType: s.subMeasurementType ?? 'inclined',
                    dip: s.dip,
                    strike: s.strike,
                    size: 36,
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList(),
        builder: (context, markers) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF1565C0),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}
