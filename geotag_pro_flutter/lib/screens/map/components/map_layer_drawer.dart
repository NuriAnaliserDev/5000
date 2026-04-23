import 'package:flutter/material.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

class MapLayerDrawer extends StatelessWidget {
  final bool isVisible;
  final double baseLayerOpacity;
  final double gisLayerOpacity;
  final double drawingLayerOpacity;
  final bool isVertexEditMode;
  final VoidCallback onToggleDrawer;
  final ValueChanged<double> onBaseOpacityChanged;
  final ValueChanged<double> onGisOpacityChanged;
  final ValueChanged<double> onDrawingOpacityChanged;
  final VoidCallback onToggleVertexEdit;

  const MapLayerDrawer({
    super.key,
    required this.isVisible,
    required this.baseLayerOpacity,
    required this.gisLayerOpacity,
    required this.drawingLayerOpacity,
    required this.isVertexEditMode,
    required this.onToggleDrawer,
    required this.onBaseOpacityChanged,
    required this.onGisOpacityChanged,
    required this.onDrawingOpacityChanged,
    required this.onToggleVertexEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      top: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggleDrawer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isVisible ? const Color(0xFF1976D2) : Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(
                isVisible ? Icons.layers_clear : Icons.layers,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          if (isVisible) ...[
            const SizedBox(height: 8),
            AppCard(
              width: 220,
              opacity: 0.6,
              blur: 15,
              baseColor: Colors.black,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        context.loc('layer_management'), 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 10, 
                          letterSpacing: 1.2
                        )
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSlider(context, context.loc('layer_base_map'), baseLayerOpacity, onBaseOpacityChanged),
                  _buildSlider(context, context.loc('layer_gis_kml'), gisLayerOpacity, onGisOpacityChanged),
                  _buildSlider(context, context.loc('layer_drawings'), drawingLayerOpacity, onDrawingOpacityChanged),
                  const Divider(color: Colors.white10),
                  TextButton.icon(
                    onPressed: onToggleVertexEdit,
                    icon: Icon(isVertexEditMode ? Icons.edit_off : Icons.edit, size: 14, color: Colors.orange),
                    label: Text(
                      isVertexEditMode ? context.loc('edit_disable') : context.loc('edit_enable'),
                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context, String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
