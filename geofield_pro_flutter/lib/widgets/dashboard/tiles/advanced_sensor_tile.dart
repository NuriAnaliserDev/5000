import 'package:flutter/material.dart';
import '../../../services/location_service.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

class AdvancedSensorTile extends StatelessWidget {
  final LocationService loc;
  final bool isDark;

  const AdvancedSensorTile({
    super.key,
    required this.loc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc('gps_performance'), 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sensorSubItem(context.loc('hdop'), '0.8', Colors.green),
              _sensorSubItem(context.loc('satellites'), '14', Colors.blue),
              _sensorSubItem(context.loc('acc_label'), '±${loc.accuracy.toStringAsFixed(1)}m', Colors.green),
            ],
          ),
          const Spacer(),
          Text(
            context.loc('rtk_fixed'), 
            style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _sensorSubItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)
        ),
        Text(
          label, 
          style: const TextStyle(fontSize: 8, color: Colors.grey)
        ),
      ],
    );
  }
}
