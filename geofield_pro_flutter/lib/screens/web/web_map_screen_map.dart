part of 'web_map_screen.dart';

mixin WebMapScreenMapMixin on WebMapScreenFields {
  Widget _buildMap(List<BoundaryPolygon> boundaries) {
    final stream = _shiftsStreamOrNull;
    if (stream == null) {
      return _buildMapInner(boundaries, shiftDocs: const []);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, shiftSnap) {
        final docs = shiftSnap.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        return _buildMapInner(boundaries, shiftDocs: docs);
      },
    );
  }

  Widget _buildMapInner(
    List<BoundaryPolygon> boundaries, {
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> shiftDocs,
  }) {
    final List<Marker> markers = [];
    final List<Polyline> polylines = [];
    final List<Polygon> polygons = [];

    for (final b in boundaries) {
      if (b.points.length >= 3) {
        final isSelected = _editingPolygon?.id == b.id;
        polygons.add(Polygon(
          points: b.points,
          color: b.displayColor.withValues(alpha: isSelected ? 0.35 : 0.15),
          borderColor: b.displayColor.withValues(alpha: isSelected ? 1.0 : 0.7),
          borderStrokeWidth: isSelected ? 3.0 : 2.0,
        ));
      }
    }
    for (final b in boundaries) {
      if (b.points.length == 2) {
        final isSelected = _editingPolygon?.id == b.id;
        polylines.add(Polyline(
          points: b.points,
          color: b.displayColor.withValues(alpha: isSelected ? 0.85 : 0.55),
          strokeWidth: isSelected ? 4.0 : 3.0,
        ));
      }
    }

    for (final doc in shiftDocs) {
      final data = doc.data();
      if (data['points'] != null) {
        final ptsList = data['points'] as List;
        final pts = ptsList
            .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
            .toList();
        if (pts.isNotEmpty) {
          polylines.add(Polyline(
              points: pts,
              strokeWidth: 3.0,
              color: Colors.redAccent.withValues(alpha: 0.6)));
        }
      }
    }

    if (_drawingPoints.isNotEmpty) {
      if (_drawingPoints.length >= 2) {
        polylines.add(Polyline(
          points: [..._drawingPoints, _drawingPoints.first],
          strokeWidth: 2.5,
          color: _selectedZoneType.color.withValues(alpha: 0.8),
        ));
      }
      for (final pt in _drawingPoints) {
        markers.add(Marker(
          point: pt,
          width: 12,
          height: 12,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedZoneType.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ));
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(41.2995, 69.2401),
        initialZoom: 13,
        onTap: _isDrawingMode
            ? (tapPos, latLng) => setState(() => _drawingPoints.add(latLng))
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.geofield.pro.flutter',
        ),
        PolygonLayer(polygons: polygons),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildDrawingHint() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _selectedZoneType.color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Xaritani bosing — ${_drawingPoints.length} nuqta',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              if (_drawingPoints.isNotEmpty) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white, size: 18),
                  onPressed: () => setState(() => _drawingPoints.removeLast()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
