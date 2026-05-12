import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../utils/app_localizations.dart';

class MapWorkshopToolRail extends StatelessWidget {
  const MapWorkshopToolRail({
    super.key,
    required this.isDrawingMode,
    required this.onOpenLayers,
    required this.onImportGis,
    required this.onStartDrawing,
    required this.onOpenProTools,
  });

  final bool isDrawingMode;
  final VoidCallback onOpenLayers;
  final VoidCallback onImportGis;
  final VoidCallback onStartDrawing;
  final VoidCallback onOpenProTools;

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) return const SizedBox.shrink();
    final t = Theme.of(context);

    return Positioned(
      right: 4,
      top: 118,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        color: t.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.loc('layer_management'),
                onPressed: onOpenLayers,
                icon: const Icon(Icons.layers, color: Color(0xFF1976D2)),
              ),
              IconButton(
                tooltip: s.map_layer_import_gis,
                onPressed: onImportGis,
                icon: const Icon(Icons.file_upload, color: Color(0xFF388E3C)),
              ),
              IconButton(
                tooltip: context.loc('layer_drawings'),
                onPressed: onStartDrawing,
                icon: Icon(
                  Icons.draw,
                  color: isDrawingMode
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF5D4037),
                ),
              ),
              const Divider(height: 1),
              IconButton(
                tooltip: s.map_pro_tools_title,
                onPressed: onOpenProTools,
                icon: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
