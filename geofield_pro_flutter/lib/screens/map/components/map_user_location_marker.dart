import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapUserLocationMarker extends StatelessWidget {
  const MapUserLocationMarker({
    super.key,
    required this.currentPosition,
    required this.headingListenable,
  });

  final dynamic currentPosition;
  final ValueListenable<double?> headingListenable;

  @override
  Widget build(BuildContext context) {
    final pos = currentPosition;
    if (pos == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          width: 64,
          height: 64,
          point: LatLng(pos.latitude, pos.longitude),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightBlueAccent.withValues(alpha: 0.18),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightBlueAccent,
                ),
              ),
              ValueListenableBuilder<double?>(
                valueListenable: headingListenable,
                builder: (context, heading, child) {
                  if (heading == null) return const SizedBox.shrink();
                  return Transform.rotate(
                    angle: heading * math.pi / 180,
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
