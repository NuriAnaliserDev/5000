import 'package:flutter/material.dart';
import '../../../models/boundary_polygon.dart';

class WebMapDrawingPanel extends StatelessWidget {
  final bool isDrawingMode;
  final ValueChanged<bool> onDrawingModeChanged;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final ZoneType selectedType;
  final ValueChanged<ZoneType> onTypeChanged;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final int pointsCount;
  final Color surfaceColor;

  const WebMapDrawingPanel({
    super.key,
    required this.isDrawingMode,
    required this.onDrawingModeChanged,
    required this.nameCtrl,
    required this.descCtrl,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onClear,
    required this.onSave,
    required this.pointsCount,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.draw_outlined, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Zona Chizish',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Switch(
                  value: isDrawingMode,
                  activeThumbColor: const Color(0xFF1565C0),
                  onChanged: onDrawingModeChanged,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  enabled: isDrawingMode,
                  decoration: InputDecoration(
                    labelText: 'Zona nomi',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  enabled: isDrawingMode,
                  decoration: InputDecoration(
                    labelText: 'Tavsif (ixtiyoriy)',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Zona turi:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ZoneType.values.map((zt) {
                    final isSelected = selectedType == zt;
                    return GestureDetector(
                      onTap: isDrawingMode ? () => onTypeChanged(zt) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? zt.color
                              : zt.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: zt.color
                                  .withValues(alpha: isSelected ? 1.0 : 0.4),
                              width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : zt.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              zt.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : zt.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (isDrawingMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Tozalash',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pointsCount >= 3 ? onSave : null,
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Saqlash',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedType.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: selectedType.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Xaritada $pointsCount nuqta chizildi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedType.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
