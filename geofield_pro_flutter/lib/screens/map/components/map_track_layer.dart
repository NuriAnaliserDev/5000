import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/track_data.dart';

class MapTrackLayer extends StatelessWidget {
  final List<TrackData> storedTracks;
  final TrackData? currentTrack;
  final double gisLayerOpacity;

  const MapTrackLayer({
    super.key,
    required this.storedTracks,
    this.currentTrack,
    this.gisLayerOpacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        ...storedTracks
            .where((t) => t.points.isNotEmpty)
            .map((t) => Polyline(
                  points: t.points.map((p) => LatLng(p.lat, p.lng)).toList(),
                  color: Colors.blue.withValues(alpha: 0.5 * gisLayerOpacity),
                  strokeWidth: 3.0,
                )),
        if (currentTrack != null && currentTrack!.points.isNotEmpty)
          Polyline(
            points: currentTrack!.points.map((p) => LatLng(p.lat, p.lng)).toList(),
            color: Colors.red,
            strokeWidth: 4.0,
          ),
      ],
    );
  }
}
