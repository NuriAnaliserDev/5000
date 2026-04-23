import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_card.dart';
import '../../../utils/geology_utils.dart';
import 'stereonet_painter.dart';
import '../../../utils/app_localizations.dart';

class StereonetTile extends StatelessWidget {
  final bool isDark;

  const StereonetTile({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationRepository>().stations;
    if (stations.isEmpty) {
      return AppCard(
        child: Center(
          child: Text(
            context.loc('stereonet_no_data'), 
            style: const TextStyle(fontSize: 10, color: Colors.grey)
          )
        )
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: const Size(100, 100),
              painter: StereonetPainter(
                stations: stations,
                typeColor: {'bedding': Colors.blue, 'foliation': Colors.orange},
                isDark: isDark,
                projection: StereonetProjection.schmidt,
                showContours: true,
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              context.loc('stereonet_summary'), 
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)
            ),
          ),
        ],
      ),
    );
  }
}
