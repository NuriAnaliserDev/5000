import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class WebMapToolbar extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onImport;

  const WebMapToolbar({
    super.key,
    required this.mapController,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbarBtn(
            icon: Icons.upload_file,
            label: 'DXF/KML Yuklash',
            color: Colors.indigo,
            onTap: onImport,
          ),
          const SizedBox(height: 8),
          _toolbarBtn(
            icon: Icons.add,
            label: '',
            color: Colors.grey.shade700,
            onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom + 1),
          ),
          const SizedBox(height: 4),
          _toolbarBtn(
            icon: Icons.remove,
            label: '',
            color: Colors.grey.shade700,
            onTap: () => mapController.move(mapController.camera.center, mapController.camera.zoom - 1),
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}
