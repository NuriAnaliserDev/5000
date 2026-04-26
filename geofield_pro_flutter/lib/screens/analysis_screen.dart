import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/station_repository.dart';
import '../utils/app_localizations.dart';

import 'analysis/tabs/statistics_tab.dart';
import 'analysis/tabs/rose_tab.dart';
import 'analysis/tabs/stereonet_tab.dart';
import 'analysis/tabs/trends_tab.dart';
import 'analysis/tabs/apparent_dip_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnalysisScreen
// Shows: statistics summary, Rose Diagram (strike), Stereonet (dip/dip-dir)
// ─────────────────────────────────────────────────────────────────────────────
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final stations = repo.stations;
    final surf = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        backgroundColor: surf,
        title: Text(context.loc('tahlil_label')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        bottom: stations.isEmpty
            ? null
            : TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF1976D2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1976D2),
                tabs: [
                  Tab(icon: const Icon(Icons.bar_chart), text: context.loc('statistics_label')),
                  Tab(icon: const Icon(Icons.rotate_right), text: context.loc('rose_diagram_title').split(' (')[0]),
                  Tab(icon: const Icon(Icons.circle_outlined), text: context.loc('stereonet_summary').split(' ')[0]),
                  Tab(icon: const Icon(Icons.trending_up), text: context.loc('trend_analysis').split(' ')[0]),
                  Tab(icon: const Icon(Icons.calculate_outlined), text: context.loc('apparent_dip_title')),
                ],
              ),
      ),
      body: stations.isEmpty
          ? _buildEmpty(context)
          : TabBarView(
              controller: _tabCtrl,
              children: [
                StatisticsTab(stations: stations),
                RoseTab(stations: stations),
                StereonetTab(stations: stations),
                TrendsTab(stations: stations),
                const ApparentDipTab(),
              ],
            ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: onSurf.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            context.loc('no_data'),
            style: TextStyle(fontSize: 16, color: onSurf.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
