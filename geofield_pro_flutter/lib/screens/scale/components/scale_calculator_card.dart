import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';

class ScaleCalculatorCard extends StatelessWidget {
  final TextEditingController realDistController;
  final TextEditingController paperDistController;
  final String unit;
  final double scaleDenominator;
  final Function(double) onScaleChanged;
  final VoidCallback onRealChanged;
  final VoidCallback onPaperChanged;

  const ScaleCalculatorCard({
    super.key,
    required this.realDistController,
    required this.paperDistController,
    required this.unit,
    required this.scaleDenominator,
    required this.onScaleChanged,
    required this.onRealChanged,
    required this.onPaperChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  context,
                  label: context.loc('real_distance'),
                  controller: realDistController,
                  suffix: unit,
                  onChanged: (v) => onRealChanged(),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.swap_horiz, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  context,
                  label: context.loc('paper_distance'),
                  controller: paperDistController,
                  suffix: 'mm',
                  onChanged: (v) => onPaperChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.loc('selected_scale'),
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [500, 1000, 2000, 5000, 10000, 25000, 50000].map((s) {
                final selected = scaleDenominator == s.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('1:$s'),
                    selected: selected,
                    onSelected: (v) {
                      if (v) {
                        onScaleChanged(s.toDouble());
                      }
                    },
                    selectedColor: const Color(0xFF1976D2),
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black),
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? suffix,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF1976D2)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
