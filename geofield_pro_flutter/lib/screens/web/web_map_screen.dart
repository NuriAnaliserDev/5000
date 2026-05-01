import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/boundary_service.dart';
import '../../services/location_service.dart';
import '../../models/boundary_polygon.dart';
import '../../l10n/app_strings.dart';
import '../../utils/firebase_ready.dart';
import '../../utils/gis_import_feedback.dart';
import '../../widgets/gis_import_precheck_dialog.dart';
import 'components/web_map_drawing_panel.dart';
import 'components/web_map_zone_list_panel.dart';
import 'components/web_map_shift_logs_panel.dart';
import 'components/web_map_toolbar.dart';

class WebMapScreen extends StatefulWidget {
  const WebMapScreen({super.key});

  @override
  State<WebMapScreen> createState() => _WebMapScreenState();
}

class _WebMapScreenState extends State<WebMapScreen> {
  final MapController _mapController = MapController();

  // ─── Drawing State ────────────────────────────────────────────────────────
  bool _isDrawingMode = false;
  final List<LatLng> _drawingPoints = [];
  ZoneType _selectedZoneType = ZoneType.workArea;
  final TextEditingController _zoneNameCtrl = TextEditingController(text: 'Yangi Zona');
  final TextEditingController _zoneDescCtrl = TextEditingController();

  // ─── Editing State ────────────────────────────────────────────────────────
  BoundaryPolygon? _editingPolygon;

  // ─── Firebase Streams (mobil bilan bir xil: users/*/shift_logs) ───────────
  Stream<QuerySnapshot<Map<String, dynamic>>>? get _shiftsStreamOrNull =>
      firestoreOrNull?.collectionGroup('shift_logs').snapshots();

  @override
  void dispose() {
    _zoneNameCtrl.dispose();
    _zoneDescCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Logic Methods ────────────────────────────────────────────────────────

  Future<void> _saveDrawnZone() async {
    if (_drawingPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida 3 nuqta chizing!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final name = _zoneNameCtrl.text.trim().isEmpty ? 'Zona' : _zoneNameCtrl.text.trim();
    final desc = _zoneDescCtrl.text.trim().isEmpty ? null : _zoneDescCtrl.text.trim();

    try {
      await context.read<BoundaryService>().addPolygonFromPoints(
            points: List.from(_drawingPoints),
            name: name,
            zoneType: _selectedZoneType,
            description: desc,
          );

      setState(() {
        _isDrawingMode = false;
        _drawingPoints.clear();
        _zoneNameCtrl.text = 'Yangi Zona';
        _zoneDescCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ "$name" saqlandi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePolygon(BoundaryPolygon polygon) async {
    final id = polygon.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zonani o\'chirish'),
        content: Text('"${polygon.name}" ni o\'chirishni tasdiqlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<BoundaryService>().deletePolygon(id);
      setState(() => _editingPolygon = null);
    }
  }

  void _showEditDialog(BoundaryPolygon polygon) {
    final nameCtrl = TextEditingController(text: polygon.name);
    final descCtrl = TextEditingController(text: polygon.description ?? '');
    ZoneType selectedType = polygon.zoneType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Zonani Tahrirlash'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Zona nomi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Tavsif (ixtiyoriy)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Zona turi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ZoneType.values.map((zt) {
                    final isSelected = selectedType == zt;
                    return FilterChip(
                      label: Text(zt.label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : zt.color, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: zt.color,
                      onSelected: (_) => setDlgState(() => selectedType = zt),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
            ElevatedButton(
              child: const Text('Saqlash'),
              onPressed: () async {
                Navigator.pop(ctx);
                final pid = polygon.id;
                if (pid != null) {
                  await context.read<BoundaryService>().updatePolygon(
                        firestoreId: pid,
                        name: nameCtrl.text.trim().isEmpty ? polygon.name : nameCtrl.text.trim(),
                        zoneType: selectedType,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onImportFromWeb() async {
    final s = GeoFieldStrings.of(context);
    try {
      final ok = await showGisImportPrecheckDialog(context);
      if (!ok || !mounted) return;
      final pos = context.read<LocationService>().currentPosition;
      final c = _mapController.camera.center;
      final r = await context.read<BoundaryService>().importFileFromWeb(
        hintLatitude: pos?.latitude ?? c.latitude,
        hintLongitude: pos?.longitude ?? c.longitude,
      );
      if (!mounted) return;
      if (r == null) return;
      if (s != null) {
        showGisImportResultSnackbar(context, s, r);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GIS: ${r.importedCount} / skipped ${r.skippedCount}'),
            backgroundColor: r.importedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Build Method ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final boundaries = context.watch<BoundaryService>().boundaries;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Map View ──────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _buildMap(boundaries),
                    WebMapToolbar(
                      mapController: _mapController,
                      onImport: _onImportFromWeb,
                    ),
                    if (_isDrawingMode) _buildDrawingHint(),
                  ],
                ),
              ),
            ),
          ),

          // ── Sidebar Panels ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            child: SizedBox(
              width: 320,
              child: Column(
                children: [
                  WebMapDrawingPanel(
                    isDrawingMode: _isDrawingMode,
                    onDrawingModeChanged: (v) => setState(() {
                      _isDrawingMode = v;
                      if (!v) _drawingPoints.clear();
                    }),
                    nameCtrl: _zoneNameCtrl,
                    descCtrl: _zoneDescCtrl,
                    selectedType: _selectedZoneType,
                    onTypeChanged: (zt) => setState(() => _selectedZoneType = zt),
                    onClear: () => setState(() => _drawingPoints.clear()),
                    onSave: _saveDrawnZone,
                    pointsCount: _drawingPoints.length,
                    surfaceColor: surfaceColor,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: WebMapShiftLogsPanel(
                      shiftsStream: _shiftsStreamOrNull,
                      surfaceColor: surfaceColor,
                      mapController: _mapController,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: WebMapZoneListPanel(
                      boundaries: boundaries,
                      surfaceColor: surfaceColor,
                      editingPolygon: _editingPolygon,
                      mapController: _mapController,
                      onEdit: _showEditDialog,
                      onDelete: _deletePolygon,
                      onSelect: (b) => setState(() => _editingPolygon = b),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<BoundaryPolygon> boundaries) {
    final stream = _shiftsStreamOrNull;
    if (stream == null) {
      return _buildMapInner(boundaries, shiftDocs: const []);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, shiftSnap) {
        final docs = shiftSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
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
          polylines
              .add(Polyline(points: pts, strokeWidth: 3.0, color: Colors.redAccent.withValues(alpha: 0.6)));
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
        onTap: _isDrawingMode ? (tapPos, latLng) => setState(() => _drawingPoints.add(latLng)) : null,
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
