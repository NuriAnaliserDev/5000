import 'package:flutter/material.dart';
import '../../../utils/app_card.dart';
import '../../../utils/app_localizations.dart';

class MapProjectionControls extends StatelessWidget {
  final bool showProjections;
  final double projectionDepth;
  final VoidCallback onToggleProjections;
  final ValueChanged<double> onDepthChanged;

  const MapProjectionControls({
    super.key,
    required this.showProjections,
    required this.projectionDepth,
    required this.onToggleProjections,
    required this.onDepthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          top: 140,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'projToggle',
            backgroundColor: showProjections ? Colors.green.shade700 : Colors.white,
            child: Icon(Icons.layers_outlined, color: showProjections ? Colors.white : Colors.black87),
            onPressed: onToggleProjections,
          ),
        ),
        if (showProjections)
          Positioned(
            left: 16,
            right: 80,
            bottom: 160,
            child: AppCard(
              baseColor: Colors.black,
              opacity: 0.6,
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.loc('projection_depth')}: ${projectionDepth.toInt()} m',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Slider(
                          value: projectionDepth,
                          min: 0,
                          max: 2000,
                          divisions: 20,
                          activeColor: Colors.greenAccent,
                          onChanged: onDepthChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
