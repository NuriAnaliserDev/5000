import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/mine_report.dart';

class WebAnalyticsGradePieCard extends StatelessWidget {
  final List<MineReport> oreBlocks;

  const WebAnalyticsGradePieCard({super.key, required this.oreBlocks});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      height: 450,
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
          const Text("Tosh Sifati (Ore Block Grade)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 55,
                sections: _buildGradePieSections(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildGradeLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildGradePieSections() {
    int hg = 0, mg = 0, lg = 0, waste = 0;
    for (var b in oreBlocks) {
      final String gradeStr =
          b.parsedData['grade']?.toString().toUpperCase() ?? '';
      if (gradeStr.contains('HG')) {
        hg++;
      } else if (gradeStr.contains('MG')) {
        mg++;
      } else if (gradeStr.contains('LG')) {
        lg++;
      } else {
        waste++;
      }
    }

    final total = hg + mg + lg + waste;
    if (total == 0) {
      return [
        PieChartSectionData(
            value: 1, color: Colors.grey, title: 'Ma\'lumot yo\'q', radius: 50)
      ];
    }

    return [
      if (hg > 0)
        PieChartSectionData(
          value: hg.toDouble(),
          color: const Color(0xFFE53935),
          title: '${((hg / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      if (mg > 0)
        PieChartSectionData(
          value: mg.toDouble(),
          color: const Color(0xFFFF9800),
          title: '${((mg / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      if (lg > 0)
        PieChartSectionData(
          value: lg.toDouble(),
          color: const Color(0xFF1565C0),
          title: '${((lg / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      if (waste > 0)
        PieChartSectionData(
          value: waste.toDouble(),
          color: const Color(0xFF795548),
          title: '${((waste / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
    ];
  }

  Widget _buildGradeLegend() {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _Legend(color: Color(0xFFE53935), text: "HG (Yuqori)"),
        _Legend(color: Color(0xFFFF9800), text: "MG (O'rta)"),
        _Legend(color: Color(0xFF1565C0), text: "LG (Past)"),
        _Legend(color: Color(0xFF795548), text: "Waste"),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
