import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mine_report_repository.dart';
import '../../services/station_repository.dart';
import '../../models/mine_report.dart';
import 'components/web_analytics_kpi_row.dart';
import 'components/web_analytics_grade_pie_card.dart';
import 'components/web_analytics_production_bar_card.dart';
import 'components/web_analytics_structural_section.dart';

class WebAnalyticsScreen extends StatelessWidget {
  const WebAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportRepo = context.watch<MineReportRepository>();
    final stations = context.watch<StationRepository>().stations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<MineReport>>(
        stream: reportRepo.streamVerifiedReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final reports = snapshot.data ?? [];
          if (reports.isEmpty && stations.isEmpty) {
            return _buildEmptyState();
          }

          final oreBlocks = reports.where((r) => r.reportType == 'ore_block').toList();
          final rcDrills = reports.where((r) => r.reportType == 'rc_drill').toList();
          final oreStockpile = reports.where((r) => r.reportType == 'ore_stockpile').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── KPI Row ──────────────────────────────────────────────────
                WebAnalyticsKpiRow(
                  oreBlocks: oreBlocks,
                  rcDrills: rcDrills,
                  oreStockpile: oreStockpile,
                ),
                const SizedBox(height: 20),

                // ── Charts Row ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: WebAnalyticsGradePieCard(oreBlocks: oreBlocks),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: WebAnalyticsProductionBarCard(oreBlocks: oreBlocks),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Structural Analysis ──────────────────────────────────────
                WebAnalyticsStructuralSection(stations: stations),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "Hozircha tahlil uchun ma'lumotlar mavjud emas.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
