import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';

class StationSampleSection extends StatelessWidget {
  final TextEditingController sampleIdController;
  final TextEditingController sampleTypeController;
  final int confidence;
  final String munsellColor;
  final ValueChanged<int> onConfidenceChanged;
  final VoidCallback onPickMunsell;

  const StationSampleSection({
    super.key,
    required this.sampleIdController,
    required this.sampleTypeController,
    required this.confidence,
    required this.munsellColor,
    required this.onConfidenceChanged,
    required this.onPickMunsell,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formFill = isDark ? const Color(0xFF181818) : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, context.loc('sample_data')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('sample_id'),
                controller: sampleIdController,
                hint: 'S-001',
                fillColor: formFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('sample_type'),
                controller: sampleTypeController,
                hint: 'Hand Specimen',
                fillColor: formFill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.loc('confidence'), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Slider(
                    value: confidence.toDouble(),
                    min: 1, max: 5,
                    divisions: 4,
                    label: confidence.toString(),
                    onChanged: (v) => onConfidenceChanged(v.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.loc('munsell'), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onPickMunsell,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: formFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(munsellColor, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    required Color fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
