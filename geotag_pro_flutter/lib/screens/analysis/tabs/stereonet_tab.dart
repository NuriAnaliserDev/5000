import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_scroll_physics.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/stereonet_density.dart';
import '../../../widgets/dashboard/tiles/stereonet_painter.dart';
import '../components/analysis_info_tile.dart';

class StereonetTab extends StatefulWidget {
  const StereonetTab({super.key, required this.stations});
  final List<Station> stations;

  @override
  State<StereonetTab> createState() => _StereonetTabState();
}

class _StereonetTabState extends State<StereonetTab> {
  StereonetProjection _proj = StereonetProjection.schmidt;
  bool _showContours = false;
  bool _showGreatCircles = false;
  bool _showMeanVector = false;
  List<List<double>>? _densityGrid;
  int _densityToken = 0;
  Object? _lastDensityKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    final types = widget.stations.map((s) => s.measurementType ?? 'bedding').toSet().toList();
    final colors = [
      const Color(0xFF1976D2),
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final typeColor = {for (int i = 0; i < types.length; i++) types[i]: colors[i % colors.length]};

    return ListView(
      physics: AppScrollPhysics.list(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          _proj == StereonetProjection.wulff
              ? context.loc('stereonet_wulff')
              : context.loc('stereonet_schmidt'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, letterSpacing: 2, color: onSurf.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _proj == StereonetProjection.wulff
              ? context.loc('stereonet_wulff_desc')
              : context.loc('stereonet_schmidt_desc'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Schmidt'),
              selected: _proj == StereonetProjection.schmidt,
              onSelected: (val) {
                if (val) setState(() => _proj = StereonetProjection.schmidt);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Wulff'),
              selected: _proj == StereonetProjection.wulff,
              onSelected: (val) {
                if (val) setState(() => _proj = StereonetProjection.wulff);
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.loc('density_heatmap'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: _showContours,
              onChanged: (val) => setState(() => _showContours = val),
            ),
            const SizedBox(width: 8),
            Text(context.loc('stereonet_planes'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: _showGreatCircles,
              onChanged: (val) => setState(() => _showGreatCircles = val),
            ),
            const SizedBox(width: 8),
            Text(context.loc('stereonet_mean'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: _showMeanVector,
              onChanged: (val) => setState(() => _showMeanVector = val),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
            child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final r = size / 2 - 12;
                final dKey = Object.hash(
                    Object.hashAll(widget.stations.map((s) =>
                        Object.hash(s.strike, s.dip, s.measurements?.length ?? 0))),
                    _proj,
                    _showContours,
                    r.round());
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (!_showContours) {
                    if (_densityGrid != null) {
                      setState(() {
                        _densityGrid = null;
                        _lastDensityKey = null;
                      });
                    }
                    return;
                  }
                  if (dKey == _lastDensityKey) return;
                  _lastDensityKey = dKey;
                  final t = ++_densityToken;
                  runStereonetDensityCompute(
                    stations: widget.stations,
                    radius: r,
                    projection: _proj,
                  ).then((g) {
                    if (mounted && t == _densityToken) {
                      setState(() => _densityGrid = g);
                    }
                  });
                });
                return InteractiveViewer(
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(details, size),
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: StereonetPainter(
                        stations: widget.stations,
                        typeColor: typeColor,
                        isDark: isDark,
                        projection: _proj,
                        showContours: _showContours,
                        densityGrid: _densityGrid,
                        showGreatCircles: _showGreatCircles,
                        showMeanVector: _showMeanVector,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: types.map((t) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: typeColor[t], shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(t.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          )).toList(),
        ),
        const SizedBox(height: 20),
        AnalysisInfoTile(
          icon: Icons.info_outline,
          label: context.loc('stereonet_density_hint_label'),
          value: context.loc('stereonet_density_hint_value'),
        ),
      ],
    );
  }

  void _handleTap(TapUpDetails details, double size) {
    final double w = size;
    final double cx = w / 2;
    final double cy = w / 2;
    final double r = w / 2 - 12;

    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    final points = <ProjectedPoint>[];
    for (final s in widget.stations) {
      final p1 = StereonetEngine.projectPole(
        dipDirection: s.dipDirection ?? ((s.strike + 90) % 360),
        dip: s.dip,
        radius: r,
        proj: _proj,
        data: s,
      );
      points.add(p1);

      if (s.measurements != null) {
        for (final mD in s.measurements!) {
          points.add(StereonetEngine.projectPole(
            dipDirection: mD.dipDirection,
            dip: mD.dip,
            radius: r,
            proj: _proj,
            data: s,
          ));
        }
      }

    }

    double minDistSq = double.infinity;
    Station? closestStation;

    for (final pt in points) {
      final targetX = cx + pt.x;
      final targetY = cy + pt.y;
      final distSq = pow(tapX - targetX, 2) + pow(tapY - targetY, 2);
      if (distSq < minDistSq && distSq < 100) { 
        minDistSq = distSq.toDouble();
        if (pt.data is Station) {
          closestStation = pt.data;
        }
      }
    }

    if (closestStation != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(closestStation!.name),
          content: Text(
            '${context.loc('station_project_label')}: ${closestStation.project ?? context.loc('unknown')}\n'
            '${context.loc('analysis_primary_measurement')}: Strike ${closestStation.strike.toStringAsFixed(0)}°, Dip ${closestStation.dip.toStringAsFixed(0)}°\n'
            '${context.loc('analysis_extra_measurements')}: ${closestStation.measurements?.length ?? 0} ta\n\n'
            '${context.loc('analysis_rock_type')}: ${closestStation.rockType ?? "-"}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.loc('close')),
            )
          ],
        ),
      );
    }
  }
}
