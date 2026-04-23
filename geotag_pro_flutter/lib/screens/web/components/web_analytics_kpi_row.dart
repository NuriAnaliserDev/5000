import 'package:flutter/material.dart';
import '../../../models/mine_report.dart';

class WebAnalyticsKpiRow extends StatelessWidget {
  final List<MineReport> oreBlocks;
  final List<MineReport> rcDrills;
  final List<MineReport> oreStockpile;

  const WebAnalyticsKpiRow({
    super.key,
    required this.oreBlocks,
    required this.rcDrills,
    required this.oreStockpile,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        _buildKpiCard(t, "Ore Block", "${oreBlocks.length}", Icons.fire_truck, const Color(0xFF1565C0)),
        const SizedBox(width: 12),
        _buildKpiCard(t, "RC Burg'ulash", "${rcDrills.length}", Icons.precision_manufacturing, const Color(0xFF6A1B9A)),
        const SizedBox(width: 12),
        _buildKpiCard(t, "Stockpile", "${oreStockpile.length}", Icons.stacked_bar_chart, const Color(0xFF2E7D32)),
      ],
    );
  }

  Widget _buildKpiCard(ThemeData t, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
