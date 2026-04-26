import 'package:flutter/material.dart';
import '../../../utils/auto_scroll_text.dart';

class ScaleColorChart extends StatelessWidget {
  const ScaleColorChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> colors = [
      {'name': 'N 1 (Black)', 'color': const Color(0xFF1E1E1E)},
      {'name': 'N 3 (D. Grey)', 'color': const Color(0xFF4A4A4A)},
      {'name': 'N 5 (M. Grey)', 'color': const Color(0xFF808080)},
      {'name': 'N 7 (L. Grey)', 'color': const Color(0xFFB0B0B0)},
      {'name': 'N 9 (White)', 'color': const Color(0xFFF0F0F0)},
      {'name': '10R 3/4 (D. Red)', 'color': const Color(0xFF5A2A22)},
      {'name': '10R 6/6 (L. Red)', 'color': const Color(0xFFCB6D51)},
      {'name': '10YR 4/2 (D. Brown)', 'color': const Color(0xFF6B5842)},
      {'name': '10YR 6/6 (Yellow)', 'color': const Color(0xFFC49A45)},
      {'name': '10YR 8/2 (L. Yellow)', 'color': const Color(0xFFE2D0B6)},
      {'name': '5Y 4/1 (Olive)', 'color': const Color(0xFF5A5A48)},
      {'name': '5GY 6/4 (Y. Green)', 'color': const Color(0xFF8B9D66)},
      {'name': '5B 4/1 (D. Blue)', 'color': const Color(0xFF485865)},
      {'name': '5B 7/1 (L. Blue)', 'color': const Color(0xFFA5B4C2)},
      {'name': '5R 3/4 (Maroon)', 'color': const Color(0xFF6B2A31)},
      {'name': '5R 7/4 (Pink)', 'color': const Color(0xFFD6949C)},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index]['color'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: AutoScrollText(
                  text: colors[index]['name'], 
                  style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
