import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/station.dart';
import '../../../widgets/structural_3d_painter.dart';

class DashboardDesktop3DCard extends StatefulWidget {
  final List<Station> stations;

  const DashboardDesktop3DCard({super.key, required this.stations});

  @override
  State<DashboardDesktop3DCard> createState() => _DashboardDesktop3DCardState();
}

class _DashboardDesktop3DCardState extends State<DashboardDesktop3DCard> {
  double _rotX = 0.5;
  double _rotY = 0.5;

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) {
      return _buildEmpty();
    }

    final avgLat = widget.stations.map((e) => e.lat).reduce((a, b) => a + b) /
        widget.stations.length;
    final avgLng = widget.stations.map((e) => e.lng).reduce((a, b) => a + b) /
        widget.stations.length;
    final avgAlt =
        widget.stations.map((e) => e.altitude).reduce((a, b) => a + b) /
            widget.stations.length;

    return GestureDetector(
      onPanUpdate: (d) => setState(() {
        _rotY += d.delta.dx * 0.01;
        _rotX -= d.delta.dy * 0.01;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.view_in_ar, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text('3D Geological Model',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            Expanded(
              child: ClipRRect(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: Structural3DPainter(
                    stations: widget.stations,
                    center: LatLng(avgLat, avgLng),
                    centerAlt: avgAlt,
                    rotX: _rotX,
                    rotY: _rotY,
                    zoom: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: const Center(
          child: Text('No data for 3D', style: TextStyle(color: Colors.grey))),
    );
  }
}
