import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_strings.dart';

class MapThreeDButton extends StatelessWidget {
  final LatLng centerPoint;
  const MapThreeDButton({super.key, required this.centerPoint});

  @override
  Widget build(BuildContext context) {
    final tip = GeoFieldStrings.of(context)?.map_3d_tooltip ?? '';
    return Tooltip(
      message: tip,
      child: FloatingActionButton(
        heroTag: 'three_d_btn',
        onPressed: () {
          context.push(
            '/three_d',
            extra: centerPoint,
          );
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
      ),
    );
  }
}
