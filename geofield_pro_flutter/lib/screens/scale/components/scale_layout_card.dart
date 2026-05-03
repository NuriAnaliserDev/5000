import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/auto_scroll_text.dart';

class ScaleLayoutCard extends StatelessWidget {
  final String selectedPaper;
  final List<String> paperFormats;
  final TextEditingController customWidthCtrl;
  final TextEditingController customHeightCtrl;
  final double scaleDenominator;
  final Function(String) onPaperChanged;
  final VoidCallback onCustomChanged;

  const ScaleLayoutCard({
    super.key,
    required this.selectedPaper,
    required this.paperFormats,
    required this.customWidthCtrl,
    required this.customHeightCtrl,
    required this.scaleDenominator,
    required this.onPaperChanged,
    required this.onCustomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    double pWidthCm = 21.0;
    double pHeightCm = 29.7;

    if (selectedPaper == 'custom') {
      pWidthCm = double.tryParse(customWidthCtrl.text) ?? 0;
      pHeightCm = double.tryParse(customHeightCtrl.text) ?? 0;
    } else {
      final matches =
          RegExp(r'([\d.]+)\s*x\s*([\d.]+)').firstMatch(selectedPaper);
      if (matches != null) {
        pWidthCm = double.parse(matches.group(1)!);
        pHeightCm = double.parse(matches.group(2)!);
      }
    }

    final groundWidthM = (pWidthCm * scaleDenominator) / 100.0;
    final groundHeightM = (pHeightCm * scaleDenominator) / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black12,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.loc('paper_format_label'),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.black : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
            dropdownColor: isDark ? Colors.black : Colors.white,
            isExpanded: true,
            initialValue: selectedPaper,
            items: paperFormats
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p == 'custom' ? context.loc('custom_input') : p,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) onPaperChanged(val);
            },
          ),
          if (selectedPaper == 'custom') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    context,
                    label: context.loc('width_cm'),
                    controller: customWidthCtrl,
                    onChanged: (v) => onCustomChanged(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    context,
                    label: context.loc('height_cm'),
                    controller: customHeightCtrl,
                    onChanged: (v) => onCustomChanged(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(context.loc('ground_area_label'),
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AutoScrollText(
                    text:
                        '${groundWidthM.toStringAsFixed(1)} m  x  ${groundHeightM.toStringAsFixed(1)} m',
                    style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.loc('layout_explanation'),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
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
