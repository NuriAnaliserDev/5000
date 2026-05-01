import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/boundary_polygon.dart';

class WebMapZoneListPanel extends StatelessWidget {
  final List<BoundaryPolygon> boundaries;
  final Color surfaceColor;
  final BoundaryPolygon? editingPolygon;
  final MapController mapController;
  final Function(BoundaryPolygon) onEdit;
  final Function(BoundaryPolygon) onDelete;
  final Function(BoundaryPolygon) onSelect;

  const WebMapZoneListPanel({
    super.key,
    required this.boundaries,
    required this.surfaceColor,
    this.editingPolygon,
    required this.mapController,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Zonalar (${boundaries.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: boundaries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Hali zona yo\'q', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('Chizish rejimini yoqing', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: boundaries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
                    itemBuilder: (context, index) {
                      final b = boundaries[index];
                      final isSelected = editingPolygon?.id == b.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: b.displayColor.withValues(alpha: 0.08),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: b.displayColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: b.displayColor, width: 2),
                          ),
                          child: Icon(_zoneIcon(b.zoneType), color: b.displayColor, size: 18),
                        ),
                        title: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          b.zoneType.label,
                          style: TextStyle(fontSize: 11, color: b.displayColor, fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.my_location, size: 18),
                              color: Colors.blue,
                              tooltip: 'Xaritada ko\'rsatish',
                              onPressed: () {
                                if (b.points.isNotEmpty) {
                                  final centerLat = b.points.map((p) => p.latitude).reduce((a, c) => a + c) / b.points.length;
                                  final centerLng = b.points.map((p) => p.longitude).reduce((a, c) => a + c) / b.points.length;
                                  mapController.move(LatLng(centerLat, centerLng), 15);
                                  onSelect(b);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: Colors.grey,
                              tooltip: 'Tahrirlash',
                              onPressed: () => onEdit(b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.red.shade300,
                              tooltip: 'O\'chirish',
                              onPressed: () => onDelete(b),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _zoneIcon(ZoneType type) {
    switch (type) {
      case ZoneType.workArea:  return Icons.construction;
      case ZoneType.cafeteria: return Icons.restaurant;
      case ZoneType.restArea:  return Icons.bed;
      case ZoneType.hazard:    return Icons.warning_amber;
      case ZoneType.base:      return Icons.home_outlined;
    }
  }
}
