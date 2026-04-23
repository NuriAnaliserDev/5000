import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/station.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/stereonet_density.dart';
import 'stereonet_painter.dart';

class StereonetTile extends StatefulWidget {
  final bool isDark;

  const StereonetTile({
    super.key,
    required this.isDark,
  });

  @override
  State<StereonetTile> createState() => _StereonetTileState();
}

class _StereonetTileState extends State<StereonetTile> {
  static const _size = 100.0;
  List<List<double>>? _densityGrid;
  int? _scheduledForGen;

  Future<void> _loadForStations(
    int gen, List<Station> stations) async {
    const r = _size / 2 - 12;
    final g = await runStereonetDensityCompute(
      stations: stations,
      radius: r,
      projection: StereonetProjection.schmidt,
    );
    if (!mounted) return;
    if (_scheduledForGen != gen) return;
    setState(() => _densityGrid = g);
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.select<StationRepository, int>((r) => r.dataGeneration);
    final stations = context.watch<StationRepository>().stations;
    if (stations.isEmpty) {
      return AppCard(
        child: Center(
          child: Text(
            context.loc('stereonet_no_data'),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    if (_scheduledForGen != gen) {
      _scheduledForGen = gen;
      _loadForStations(gen, stations);
    }

    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: const Size(_size, _size),
              painter: StereonetPainter(
                stations: stations,
                typeColor: const {'bedding': Colors.blue, 'foliation': Colors.orange},
                isDark: widget.isDark,
                projection: StereonetProjection.schmidt,
                showContours: true,
                densityGrid: _densityGrid,
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              context.loc('stereonet_summary'),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
