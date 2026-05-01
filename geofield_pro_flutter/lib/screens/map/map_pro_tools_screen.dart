import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// [GlobalMapScreen] pro-paneldan qaytadigan amal.
enum MapProToolAction {
  openLayerDrawer,
  importGis,
  measure,
  slice,
  structure,
  startDrawing,
  toggleEraser,
  openFieldWorkshop,
  threeD,
  stereonet,
  copyUtm,
  centerElevation,
  exportGeojson,
  toggleProjection,
}

/// Xaritadagi kuchli pro vositalar — alohida to‘liq ekran (mavzuga mos rang).
class MapProToolsScreen extends StatelessWidget {
  const MapProToolsScreen({super.key});

  void _pop(BuildContext context, MapProToolAction a) {
    Navigator.of(context).pop<MapProToolAction>(a);
  }

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.map_pro_tools_title),
        backgroundColor: t.colorScheme.surface,
        foregroundColor: t.colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            s.map_pro_tools_subtitle,
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.layers,
            title: s.layer_management,
            onTap: () => _pop(context, MapProToolAction.openLayerDrawer),
          ),
          _Tile(
            icon: Icons.file_upload,
            title: s.map_layer_import_gis,
            onTap: () => _pop(context, MapProToolAction.importGis),
          ),
          _Tile(
            icon: Icons.straighten,
            title: s.map_measure_mode,
            onTap: () => _pop(context, MapProToolAction.measure),
          ),
          _Tile(
            icon: Icons.content_cut,
            title: s.map_slice_tooltip,
            onTap: () => _pop(context, MapProToolAction.slice),
          ),
          _Tile(
            icon: Icons.architecture,
            title: s.map_structure_mode_tooltip,
            onTap: () => _pop(context, MapProToolAction.structure),
          ),
          _Tile(
            icon: Icons.edit_road,
            title: s.layer_drawings,
            onTap: () => _pop(context, MapProToolAction.startDrawing),
          ),
          _Tile(
            icon: Icons.auto_fix_off,
            title: s.map_eraser_tooltip,
            onTap: () => _pop(context, MapProToolAction.toggleEraser),
          ),
          _Tile(
            icon: Icons.view_in_ar,
            title: s.projection_depth,
            onTap: () => _pop(context, MapProToolAction.toggleProjection),
          ),
          _Tile(
            icon: Icons.view_in_ar_rounded,
            title: s.map_3d_tooltip,
            onTap: () => _pop(context, MapProToolAction.threeD),
          ),
          _Tile(
            icon: Icons.maps_home_work,
            title: s.field_workshop_fab_tooltip,
            onTap: () => _pop(context, MapProToolAction.openFieldWorkshop),
          ),
          _Tile(
            icon: Icons.analytics,
            title: s.field_workshop_stereonet,
            onTap: () => _pop(context, MapProToolAction.stereonet),
          ),
          _Tile(
            icon: Icons.gps_fixed,
            title: s.field_utm_tap,
            onTap: () => _pop(context, MapProToolAction.copyUtm),
          ),
          _Tile(
            icon: Icons.terrain,
            title: s.map_elevation_center_tooltip,
            onTap: () => _pop(context, MapProToolAction.centerElevation),
          ),
          _Tile(
            icon: Icons.ios_share,
            title: s.map_export_geojson,
            onTap: () => _pop(context, MapProToolAction.exportGeojson),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: t.colorScheme.primary, size: 28),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: onTap,
        ),
      ),
    );
  }
}
