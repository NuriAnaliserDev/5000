import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';

class StationActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onSaveAndNext;

  const StationActionButtons({
    super.key,
    required this.onSave,
    required this.onSaveAndNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onSave,
              icon: const Icon(Icons.check),
              label: Text(
                context.loc('save'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onSaveAndNext,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                context.loc('next_station'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
