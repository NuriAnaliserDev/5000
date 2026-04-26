import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/map_structure_annotation.dart';

class MapStructureMarkersLayer extends StatelessWidget {
  final List<MapStructureAnnotation> annotations;
  final double opacity;
  final void Function(MapStructureAnnotation a) onMarkerTap;

  const MapStructureMarkersLayer({
    super.key,
    required this.annotations,
    required this.opacity,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(
      markers: annotations
          .map(
            (a) => Marker(
              point: LatLng(a.lat, a.lng),
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: GestureDetector(
                  onTap: () => onMarkerTap(a),
                  child: _StructureMarkerChip(strike: a.strike, dip: a.dip),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StructureMarkerChip extends StatelessWidget {
  final double strike;
  final double dip;

  const _StructureMarkerChip({required this.strike, required this.dip});

  @override
  Widget build(BuildContext context) {
    final rad = math.pi / 2 - strike * math.pi / 180;
    return Material(
      color: Colors.amber.shade100,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: rad,
              child: Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.brown.shade900,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${strike.round()}°/${dip.round()}°',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
