import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/geology_utils.dart';

class StationStructuralSection extends StatelessWidget {
  final TextEditingController strikeController;
  final TextEditingController dipController;
  final TextEditingController dipDirectionController;
  final TextEditingController azimuthController;
  final String measurementType;
  final String subMeasurementType;
  final List<String> measurementTypes;
  final ValueChanged<String?> onMeasurementTypeChanged;
  final ValueChanged<String?> onSubMeasurementTypeChanged;

  const StationStructuralSection({
    super.key,
    required this.strikeController,
    required this.dipController,
    required this.dipDirectionController,
    required this.azimuthController,
    required this.measurementType,
    required this.subMeasurementType,
    required this.measurementTypes,
    required this.onMeasurementTypeChanged,
    required this.onSubMeasurementTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formFill = isDark ? const Color(0xFF181818) : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, context.loc('structural_data')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                label: context.loc('type'),
                value: measurementType,
                items: measurementTypes,
                onChanged: onMeasurementTypeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                context,
                label: context.loc('subtype'),
                value: subMeasurementType,
                items: GeologyUtils.getSubTypes(measurementType),
                onChanged: onSubMeasurementTypeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('strike'),
                controller: strikeController,
                hint: '0-360',
                fillColor: formFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('dip'),
                controller: dipController,
                hint: '0-90',
                fillColor: formFill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('dip_direction'),
                controller: dipDirectionController,
                hint: 'Auto',
                fillColor: formFill,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('azimuth'),
                controller: azimuthController,
                hint: '0-360',
                fillColor: formFill,
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

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181818) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              onChanged: onChanged,
              items: items.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    required Color fillColor,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          readOnly: readOnly,
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
