import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/mine_report_repository.dart';
import '../../../models/mine_report.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

class ProductionSummaryTile extends StatelessWidget {
  final bool isDark;

  const ProductionSummaryTile({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MineReport>>(
      stream: context.read<MineReportRepository>().streamVerifiedReports(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        
        // Mock data logic for grade distribution
        int hg = 45, mg = 30, waste = 25;
        if (reports.isNotEmpty) {
          // Future: Logic to parse real HG/MG from parsedData
        }

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc('grade_dist'), 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
              ),
              const Spacer(),
              SizedBox(
                height: 60,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 15,
                    sections: [
                      PieChartSectionData(value: hg.toDouble(), color: Colors.green, radius: 10, showTitle: false),
                      PieChartSectionData(value: mg.toDouble(), color: Colors.orange, radius: 10, showTitle: false),
                      PieChartSectionData(value: waste.toDouble(), color: Colors.red, radius: 10, showTitle: false),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HG: $hg%', style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('MG: $mg%', style: const TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}
