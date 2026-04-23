import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/station.dart';
import '../../../utils/geology_utils.dart';
import '../../../widgets/structural_3d_painter.dart';

class WebAnalyticsStructuralSection extends StatefulWidget {
  final List<Station> stations;

  const WebAnalyticsStructuralSection({super.key, required this.stations});

  @override
  State<WebAnalyticsStructuralSection> createState() => _WebAnalyticsStructuralSectionState();
}

class _WebAnalyticsStructuralSectionState extends State<WebAnalyticsStructuralSection> {
  double _rotX = 0.5;
  double _rotY = 0.5;
  final double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (widget.stations.isEmpty) return const SizedBox.shrink();

    final List<double> strikes = widget.stations.map((s) => s.strike).toList();
    final stats = GeologyUtils.fisherStats(strikes);
    final avgStrike = GeologyUtils.circularMean(strikes);

    // Calculate center for 3D view
    final avgLat = widget.stations.map((e) => e.lat).reduce((a, b) => a + b) / widget.stations.length;
    final avgLng = widget.stations.map((e) => e.lng).reduce((a, b) => a + b) / widget.stations.length;
    final avgAlt = widget.stations.map((e) => e.altitude).reduce((a, b) => a + b) / widget.stations.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.architecture, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              const Text("Strukturaviy Trendlar Tahlili (Global)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("${widget.stations.length} ta o'lchov nuqtasi", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatBox("O'rtacha Strike", "${avgStrike.toStringAsFixed(1)}°", Colors.blue),
              _buildStatBox("Ishonchlilik (α₉₅)", "±${stats.alpha95.toStringAsFixed(1)}°", stats.isReliable ? Colors.green : Colors.orange),
              _buildStatBox("Dispersion (κ)", stats.kappa.toStringAsFixed(1), Colors.purple),
              _buildStatBox("Resultant (R)", stats.resultantLength.toStringAsFixed(2), Colors.teal),
            ],
          ),
          const SizedBox(height: 24),
          const Text("3D STRUKTURAVIY MODEL", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotY += details.delta.dx * 0.01;
                _rotX -= details.delta.dy * 0.01;
              });
            },
            child: Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: Structural3DPainter(
                    stations: widget.stations,
                    center: LatLng(avgLat, avgLng),
                    centerAlt: avgAlt,
                    rotX: _rotX,
                    rotY: _rotY,
                    zoom: _zoom,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
