import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../tiles/fisher_reliability_tile.dart';
import '../tiles/production_summary_tile.dart';
import '../tiles/stereonet_tile.dart';
import 'dashboard_desktop_3d_card.dart';
import 'dashboard_desktop_map_card.dart';

class DashboardDesktopBentoGrid extends StatelessWidget {
  final List<Station> stations;

  final bool isDark;

  const DashboardDesktopBentoGrid(
      {super.key, required this.stations, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.4,
      children: [
        DashboardDesktop3DCard(stations: stations),
        DashboardDesktopMapCard(stations: stations),
        StereonetTile(isDark: isDark),
        FisherReliabilityTile(isDark: isDark),
        ProductionSummaryTile(isDark: isDark),
        _buildQuickActionCard(),
      ],
    );
  }

  Widget _buildQuickActionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          const Text('New Survey',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Quickly start a new geological station survey.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Launch Tool'),
          ),
        ],
      ),
    );
  }
}
