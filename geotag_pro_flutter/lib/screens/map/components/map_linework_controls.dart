import 'package:flutter/material.dart';
import '../../../utils/app_card.dart';

class MapLineworkControls extends StatelessWidget {
  final bool isDrawingMode;
  final String selectedLineType;
  final bool isCurvedMode;
  final bool isSnapEnabled;
  final int drawingPointsCount;
  final GlobalKey drawButtonKey;
  
  final VoidCallback onStartDrawing;
  final ValueChanged<String> onLineTypeChanged;
  final VoidCallback onToggleCurve;
  final VoidCallback onToggleSnap;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const MapLineworkControls({
    super.key,
    required this.isDrawingMode,
    required this.selectedLineType,
    required this.isCurvedMode,
    required this.isSnapEnabled,
    required this.drawingPointsCount,
    required this.drawButtonKey,
    required this.onStartDrawing,
    required this.onLineTypeChanged,
    required this.onToggleCurve,
    required this.onToggleSnap,
    required this.onUndo,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDrawingMode) {
      return Positioned(
        right: 16,
        top: 90,
        child: FloatingActionButton(
          key: drawButtonKey,
          heroTag: 'drawFAB',
          mini: true,
          backgroundColor: Colors.white,
          onPressed: onStartDrawing,
          child: const Icon(Icons.edit_road, color: Colors.black87),
        ),
      );
    }

    return Positioned(
      top: 90,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppCard(
            baseColor: Colors.black,
            opacity: 0.7,
            padding: const EdgeInsets.all(8),
            borderRadius: 12,
            child: Column(
              children: [
                _buildToolButton('fault', Icons.looks_two, Colors.red),
                _buildToolButton('contact', Icons.looks_one, Colors.orange),
                _buildToolButton('bedding_trace', Icons.waves, Colors.blue),
                _buildToolButton('polygon', Icons.format_shapes, Colors.green),
                const Divider(color: Colors.white24, height: 16),
                _buildToggleButton(
                  isActive: isCurvedMode,
                  activeIcon: Icons.auto_fix_high,
                  inactiveIcon: Icons.linear_scale,
                  activeColor: Colors.blueAccent,
                  onTap: onToggleCurve,
                ),
                const SizedBox(height: 8),
                _buildToggleButton(
                  isActive: isSnapEnabled,
                  activeIcon: Icons.leak_add,
                  inactiveIcon: Icons.leak_add,
                  activeColor: Colors.greenAccent,
                  onTap: onToggleSnap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'undoFAB',
            mini: true,
            backgroundColor: Colors.grey.shade800,
            onPressed: onUndo,
            child: const Icon(Icons.undo, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'cancelDrawFAB',
            mini: true,
            backgroundColor: Colors.red.shade800,
            onPressed: onCancel,
            child: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'saveDrawFAB',
            mini: true,
            backgroundColor: Colors.green.shade600,
            onPressed: drawingPointsCount < 2 ? null : onSave,
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required bool isActive,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
          border: isActive ? Border.all(color: activeColor, width: 2) : Border.all(color: Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isActive ? activeIcon : inactiveIcon, 
          color: isActive ? activeColor : Colors.white, 
          size: 20
        ),
      ),
    );
  }

  Widget _buildToolButton(String type, IconData icon, Color color) {
    final isSelected = selectedLineType == type;
    return GestureDetector(
      onTap: () => onLineTypeChanged(type),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          border: isSelected ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
