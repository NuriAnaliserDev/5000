import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/rocks_list.dart';

class StationRockSection extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController rockTypeController;
  final TextEditingController structureController;
  final TextEditingController colorController;
  final String rockType;
  final String subRockType;
  final ValueChanged<String?> onRockTypeChanged;
  final ValueChanged<String?> onSubRockTypeChanged;
  final VoidCallback onAiAnalyze;
  final bool isAiLoading;

  const StationRockSection({
    super.key,
    required this.descriptionController,
    required this.rockTypeController,
    required this.structureController,
    required this.colorController,
    required this.rockType,
    required this.subRockType,
    required this.onRockTypeChanged,
    required this.onSubRockTypeChanged,
    required this.onAiAnalyze,
    required this.isAiLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formFill = isDark ? const Color(0xFF181818) : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, context.loc('lithology')),
            TextButton.icon(
              onPressed: isAiLoading ? null : onAiAnalyze,
              icon: isAiLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 14),
              label: Text(context.loc('ai_lithology_btn'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                label: context.loc('rock_category'),
                value: rockType,
                items: rockTree.keys.toList(),
                onChanged: onRockTypeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                context,
                label: context.loc('rock_name'),
                value: subRockType,
                items: rockTree[rockType] ?? [subRockType],
                onChanged: onSubRockTypeChanged,
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
                label: context.loc('structure'),
                controller: structureController,
                fillColor: formFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                context,
                label: context.loc('color'),
                controller: colorController,
                fillColor: formFill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          label: context.loc('notes'),
          controller: descriptionController,
          hint: context.loc('notes_hint'),
          fillColor: formFill,
          maxLines: 4,
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
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              onChanged: onChanged,
              items: items.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
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
