import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/mine_report.dart';

class WebAnalyticsProductionBarCard extends StatelessWidget {
  final List<MineReport> oreBlocks;

  const WebAnalyticsProductionBarCard({super.key, required this.oreBlocks});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Oxirgi 7 Kunlik Qazish (Reyslar Soni)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 350,
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (oreBlocks.isEmpty) {
      return const Center(
          child: Text("Ma'lumot yo'q", style: TextStyle(color: Colors.grey)));
    }

    final now = DateTime.now();
    final dayFormat = DateFormat('MM/dd');
    final grouped = <String, double>{};

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      grouped[dayFormat.format(day)] = 0;
    }

    for (final report in oreBlocks) {
      final key = dayFormat.format(report.createdAt);
      if (grouped.containsKey(key)) {
        final loads = double.tryParse(
                report.parsedData['total_loads']?.toString() ?? '0') ??
            0;
        grouped[key] = (grouped[key] ?? 0) + loads;
      }
    }

    final keys = grouped.keys.toList();
    final maxY = grouped.values.fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 50 : maxY + 10,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              "${keys[group.x]} — ${rod.toY.toInt()} reys",
              const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(keys[idx],
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: List.generate(keys.length, (i) {
          final loads = grouped[keys[i]] ?? 0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: loads,
                width: 24,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
