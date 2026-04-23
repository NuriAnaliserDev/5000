import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../services/station_repository.dart';
import '../services/track_service.dart';
import '../services/location_service.dart';
import '../services/settings_controller.dart';
import '../services/boundary_service.dart';
import '../services/geological_line_repository.dart';
import '../services/tutorial_service.dart';
import '../services/presence_service.dart';
import '../models/station.dart';
import '../models/geological_line.dart';
import '../models/boundary_polygon.dart';
import '../utils/linework_utils.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_localizations.dart';
import 'cross_section_screen.dart';

// Components
import 'map/components/map_track_layer.dart';
import 'map/components/map_station_layer.dart';
import 'map/components/map_linework_layer.dart';
import 'map/components/map_team_presence_layer.dart';
import 'map/components/map_sos_signals_layer.dart';
import 'map/components/map_gps_hud.dart';
import 'map/components/map_legend.dart';
import 'map/components/map_top_bar.dart';
import 'map/components/map_live_track_stats.dart';
import 'map/components/map_slice_button.dart';
import 'map/components/map_sos_button.dart';
import 'map/components/map_linework_controls.dart';
import 'map/components/map_projection_controls.dart';
import 'map/components/map_layer_drawer.dart';
import 'map/components/map_three_d_button.dart';

class GlobalMapScreen extends StatefulWidget {
  final Map<String, dynamic>? initLocation;
  const GlobalMapScreen({super.key, this.initLocation});

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  late final FMTCTileProvider _tileProvider;
  final MapController _mapController = MapController();

  StreamSubscription<CompassEvent>? _compassSub;
  final ValueNotifier<double?> _headingNotifier = ValueNotifier(null);
  DateTime _lastHeadingUiUpdate = DateTime.now();

  final GlobalKey _drawButtonKey = GlobalKey();
  final GlobalKey _downloadButtonKey = GlobalKey();

  bool _isDrawingMode = false;
  List<LatLng> _drawingPoints = [];
  String _selectedLineType = 'fault';
  bool _isCurvedMode = false;
  double _projectionDepth = 0;
  bool _showProjections = false;
  bool _isSnapEnabled = true; 
  
  double _baseLayerOpacity = 1.0;
  double _gisLayerOpacity = 0.6;
  double _drawingLayerOpacity = 1.0;
  bool _showLayerDrawer = false;

  String? _editingPolygonId;
  int? _selectedVertexIndex;
  bool _isVertexEditMode = false;

  bool _isSliceMode = false;

  double _centerLat = 41.2995;
  double _centerLng = 69.2401;
  
  @override
  void initState() {
    super.initState();
    _initMap();
    _startCompass();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowTutorial();
      _startPresenceBroadcast();
    });
  }

  void _startPresenceBroadcast() {
    final settings = context.read<SettingsController>();
    final presence = context.read<PresenceService>();
    presence.startBroadcasting(
      () {
        final pos = context.read<LocationService>().currentPosition;
        return pos != null ? LatLng(pos.latitude, pos.longitude) : LatLng(_centerLat, _centerLng);
      },
      settings.currentUserName ?? 'Geolog',
      settings.currentUserRole ?? 'Geologist',
    );
  }

  void _checkShowTutorial() {
    final settings = context.read<SettingsController>();
    if (settings.hasSeenMapTutorial) return;

    TutorialService.showTutorial(
      context,
      targets: [
        TutorialService.createTarget(
          key: _drawButtonKey,
          identify: "draw_btn",
          title: "Chizish Rejimi",
          description: "Bu yerda siz Fault (Uzilmalar), Contact (Kontaklar) va Bedding Trace (Qatlam izlari) chizishingiz mumkin.",
        ),
        TutorialService.createTarget(
          key: _downloadButtonKey,
          identify: "download_btn",
          title: "Oflayn Xaritalar",
          description: "Dala sharoitida internet bo'lmaganda ham ishlash uchun xarita hududini yuklab oling.",
        ),
      ],
      onFinish: () => settings.hasSeenMapTutorial = true,
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _headingNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null || h.isNaN || !mounted) return;
      final target = h % 360;
      double? currentHeading = _headingNotifier.value;
      if (currentHeading == null) {
        currentHeading = target;
      } else {
        double d = target - currentHeading;
        if (d > 180) d -= 360;
        if (d < -180) d += 360;
        currentHeading = ((currentHeading + d * 0.35) % 360 + 360) % 360;
      }
      final now = DateTime.now();
      if (now.difference(_lastHeadingUiUpdate).inMilliseconds >= 80) {
        _lastHeadingUiUpdate = now;
        _headingNotifier.value = currentHeading;
      }
    });
  }

  Future<void> _initMap() async {
    _tileProvider = FMTCTileProvider(
      stores: const {
        'opentopomap': BrowseStoreStrategy.readUpdateCreate,
        'osm': BrowseStoreStrategy.readUpdateCreate,
        'satellite': BrowseStoreStrategy.readUpdateCreate,
      },
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );
  }

  String _getUrlTemplate(String style) {
    return switch (style) {
      'osm' => 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      'satellite' => 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      _ => 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    };
  }

  List<String> _getSubdomains(String style) {
    if (style == 'satellite') return const [];
    if (style == 'osm') return const ['a', 'b', 'c', 'd'];
    return const ['a', 'b', 'c'];
  }

  @override
  Widget build(BuildContext context) {
    // PERFORMANCE FIX: context.select — faqat kerakli qiymat o'zgarganda rebuild
    // context.watch × 5 = har qaysi service o'zgarganda BUTUN build() qayta ishlardi.
    final stations = context.select<StationRepository, List<Station>>(
      (repo) => repo.stations,
    );
    final currentTrack = context.select<TrackService, dynamic>(
      (svc) => svc.currentTrack,
    );
    final mapStyle = context.select<SettingsController, String>(
      (s) => s.mapStyle,
    );
    final settings = context.read<SettingsController>();
    final boundaries = context.select<BoundaryService, List<BoundaryPolygon>>(
      (svc) => svc.boundaries,
    );
    final boundarySvc = context.read<BoundaryService>();
    final geoLines = context.select<GeologicalLineRepository, List<GeologicalLine>>(
      (repo) => repo.getAllLines(),
    );
    final trackSvc = context.read<TrackService>();
    final locationSvc = context.read<LocationService>();
    final currentPos = locationSvc.currentPosition;

    LatLng center = widget.initLocation != null 
        ? LatLng(widget.initLocation!['lat'], widget.initLocation!['lng'])
        : (currentPos != null ? LatLng(currentPos.latitude, currentPos.longitude) 
        : (stations.isNotEmpty ? LatLng(stations.first.lat, stations.first.lng) : const LatLng(41.2995, 69.2401)));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                onTap: (tapPosition, point) => _handleMapTap(point, boundarySvc),
                onPositionChanged: (pos, hasGesture) {
                  _centerLat = pos.center.latitude;
                  _centerLng = pos.center.longitude;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _getUrlTemplate(mapStyle),
                  subdomains: _getSubdomains(mapStyle),
                  userAgentPackageName: 'com.geofield.pro.flutter',
                  maxNativeZoom: mapStyle == 'satellite' ? 17 : 15,
                  maxZoom: 18,
                  tileProvider: _tileProvider,
                ),
                MapTrackLayer(
                  storedTracks: trackSvc.storedTracks,
                  currentTrack: trackSvc.currentTrack,
                  gisLayerOpacity: _gisLayerOpacity,
                ),
                MapLineworkLayer(
                  geoLines: geoLines,
                  isDrawingMode: _isDrawingMode,
                  drawingPoints: _drawingPoints,
                  selectedLineType: _selectedLineType,
                  isCurvedMode: _isCurvedMode,
                ),
                if (_isSliceMode && _drawingPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _drawingPoints, color: Colors.orange, strokeWidth: 3.0),
                    ],
                  ),
                if (_isVertexEditMode && _editingPolygonId != null)
                  PolylineLayer(polylines: _buildVertexMarkers(boundaries)),
                
                PolygonLayer(
                  polygons: [
                    ...boundaries.map<Polygon>((b) => _buildBoundaryPolygon(b, currentPos)),
                    ...geoLines.where((l) => l.isClosed).map((l) => _buildLinePolygon(l)),
                    if (_isDrawingMode && _selectedLineType == 'polygon' && _drawingPoints.length >= 3)
                       Polygon(
                         points: _drawingPoints,
                         color: Color(int.parse(GeologicalLine.defaultColorHex(_selectedLineType), radix: 16) + 0x66000000),
                         borderColor: Colors.transparent,
                         borderStrokeWidth: 0,
                       ),
                  ],
                ),
                MapStationLayer(
                  stations: stations,
                  onStationTap: (s) => Navigator.of(context).pushNamed('/station', arguments: s.key as int?),
                ),
                if (widget.initLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40, height: 40,
                        point: center,
                        child: const Icon(Icons.pin_drop, color: Colors.redAccent, size: 40),
                      ),
                    ],
                  ),
                const MapTeamPresenceLayer(),
                const MapSosSignalsLayer(),
                _buildUserLocationMarker(currentPos),
              ],
            ), 
            const MapGpsHud(),
            MapLegend(stations: stations, currentPos: currentPos, mapController: _mapController),
            MapTopBar(
              stationsCount: stations.length,
              settings: settings,
              onStylePressed: () => _showMapStyleSelector(context, settings),
              onSearchPressed: () {},
            ),
            if (currentTrack != null) MapLiveTrackStats(track: trackSvc.currentTrack!),
            _buildSideControls(),
            MapLineworkControls(
              isDrawingMode: _isDrawingMode,
              selectedLineType: _selectedLineType,
              isCurvedMode: _isCurvedMode,
              isSnapEnabled: _isSnapEnabled,
              drawingPointsCount: _drawingPoints.length,
              drawButtonKey: _drawButtonKey,
              onStartDrawing: () => setState(() {
                _isDrawingMode = true;
                _isSliceMode = false;
                _drawingPoints.clear();
              }),
              onLineTypeChanged: (type) => setState(() => _selectedLineType = type),
              onToggleCurve: () => setState(() => _isCurvedMode = !_isCurvedMode),
              onToggleSnap: () => setState(() => _isSnapEnabled = !_isSnapEnabled),
              onUndo: () => setState(() { if (_drawingPoints.isNotEmpty) _drawingPoints.removeLast(); }),
              onCancel: () => setState(() { _isDrawingMode = false; _drawingPoints.clear(); }),
              onSave: _saveDrawing,
            ),
            MapProjectionControls(
              showProjections: _showProjections,
              projectionDepth: _projectionDepth,
              onToggleProjections: () => setState(() => _showProjections = !_showProjections),
              onDepthChanged: (v) => setState(() => _projectionDepth = v),
            ),
            MapLayerDrawer(
              isVisible: _showLayerDrawer,
              baseLayerOpacity: _baseLayerOpacity,
              gisLayerOpacity: _gisLayerOpacity,
              drawingLayerOpacity: _drawingLayerOpacity,
              isVertexEditMode: _isVertexEditMode,
              onToggleDrawer: () => setState(() => _showLayerDrawer = !_showLayerDrawer),
              onBaseOpacityChanged: (v) => setState(() => _baseLayerOpacity = v),
              onGisOpacityChanged: (v) => setState(() => _gisOpacityChanged(v)),
              onDrawingOpacityChanged: (v) => setState(() => _drawingLayerOpacity = v),
              onToggleVertexEdit: () => setState(() {
                _isVertexEditMode = !_isVertexEditMode;
                if (!_isVertexEditMode) { _editingPolygonId = null; _selectedVertexIndex = null; }
              }),
            ),
            MapThreeDButton(centerPoint: LatLng(_centerLat, _centerLng)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/map'),
    );
  }

  void _gisOpacityChanged(double v) => _gisLayerOpacity = v;

  Widget _buildSideControls() {
    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 310,
          child: MapSliceButton(
            isSliceMode: _isSliceMode,
            onPressed: () {
              setState(() {
                _isSliceMode = !_isSliceMode;
                _isDrawingMode = false;
                _drawingPoints = [];
              });
              if (_isSliceMode) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.locRead('select_two_points'))));
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 240,
          child: MapSosButton(currentCenter: LatLng(_centerLat, _centerLng)),
        ),
      ],
    );
  }

  void _handleMapTap(LatLng point, BoundaryService boundarySvc) {
    if (_isVertexEditMode && _editingPolygonId != null) {
      _moveVertex(point);
    } else if (_isVertexEditMode && _editingPolygonId == null) {
      final picked = boundarySvc.getBoundaryAt(point);
      if (picked != null) {
        setState(() {
           _editingPolygonId = picked.firestoreId;
           _selectedVertexIndex = 0;
        });
      }
    } else if (_isDrawingMode) {
      LatLng finalPoint = point;
      if (_isSnapEnabled) {
        final stations = context.read<StationRepository>().stations;
        final snapped = LineworkUtils.findNearestSnapPoint(point, stations.map((s) => LatLng(s.lat, s.lng)).toList());
        if (snapped != null) { finalPoint = snapped; HapticFeedback.lightImpact(); }
      }
      setState(() => _drawingPoints.add(finalPoint));
    } else if (_isSliceMode) {
      setState(() => _drawingPoints.add(point));
      if (_drawingPoints.length == 2) _finalizeSlice();
    }
  }

  Polygon _buildBoundaryPolygon(BoundaryPolygon b, dynamic currentPos) {
    final isActive = currentPos != null && b.containsPoint(LatLng(currentPos.latitude, currentPos.longitude));
    return Polygon(
      points: b.points,
      color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.1 * _gisLayerOpacity),
      borderColor: isActive ? Colors.greenAccent : Colors.blueAccent.withValues(alpha: _gisLayerOpacity),
      borderStrokeWidth: isActive ? 3.0 : 2.0,
    );
  }

  Polygon _buildLinePolygon(GeologicalLine l) {
    Color color = l.colorHex != null 
        ? Color(int.parse(l.colorHex!, radix: 16) + 0xFF000000) 
        : Color(int.parse(GeologicalLine.defaultColorHex(l.lineType), radix: 16) + 0xFF000000);
    return Polygon(
      points: List.generate(l.lats.length, (i) => LatLng(l.lats[i], l.lngs[i])),
      color: color.withValues(alpha: 0.4),
      borderColor: color,
      borderStrokeWidth: l.strokeWidth,
    );
  }

  Widget _buildUserLocationMarker(dynamic currentPos) {
    if (currentPos == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          width: 64, height: 64,
          point: LatLng(currentPos.latitude, currentPos.longitude),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.lightBlueAccent.withValues(alpha: 0.18))),
              Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.lightBlueAccent)),
              ValueListenableBuilder<double?>(
                valueListenable: _headingNotifier,
                builder: (context, heading, child) {
                  if (heading == null) return const SizedBox.shrink();
                  return Transform.rotate(
                    angle: heading * math.pi / 180,
                    child: Transform.translate(offset: const Offset(0, -18), child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 22)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapStyleSelector(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _styleTile(context, settings, 'opentopomap', Icons.terrain),
          _styleTile(context, settings, 'osm', Icons.map),
          _styleTile(context, settings, 'satellite', Icons.satellite),
        ],
      ),
    );
  }

  Widget _styleTile(BuildContext context, SettingsController settings, String style, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(context.loc(style)),
      selected: settings.mapStyle == style,
      onTap: () { settings.mapStyle = style; Navigator.pop(context); },
    );
  }

  Future<void> _saveDrawing() async {
    final nameCtrl = TextEditingController(text: '${GeologicalLine.localizedName(_selectedLineType)} 1');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('save_drawing_title')),
        content: TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.loc('drawing_name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.loc('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.loc('save_label'))),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final newLine = GeologicalLine(
      id: const Uuid().v4(),
      name: nameCtrl.text,
      lineType: _selectedLineType,
      lats: _drawingPoints.map((p) => p.latitude).toList(),
      lngs: _drawingPoints.map((p) => p.longitude).toList(),
      date: DateTime.now(),
      isClosed: _selectedLineType == 'polygon',
      isDashed: _selectedLineType == 'fault',
      isCurved: _isCurvedMode,
    );

    await context.read<GeologicalLineRepository>().addLine(newLine);
    setState(() { _isDrawingMode = false; _drawingPoints.clear(); });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.locRead('drawing_saved'))));
  }

  void _finalizeSlice() {
    final start = _drawingPoints[0];
    final end = _drawingPoints[1];
    setState(() { _isSliceMode = false; _drawingPoints = []; });
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CrossSectionScreen(start: start, end: end)));
  }

  List<Polyline> _buildVertexMarkers(List<BoundaryPolygon> boundaries) {
    if (_editingPolygonId == null) return [];
    final poly = boundaries.firstWhere((b) => b.firestoreId == _editingPolygonId);
    return poly.points.asMap().entries.map((entry) {
      final isSelected = _selectedVertexIndex == entry.key;
      return Polyline(points: [entry.value, entry.value], color: isSelected ? Colors.red : Colors.yellow, strokeWidth: isSelected ? 12 : 8, strokeCap: StrokeCap.round);
    }).toList();
  }

  void _moveVertex(LatLng newPos) {
    if (_editingPolygonId == null || _selectedVertexIndex == null) return;
    context.read<BoundaryService>().updatePolygonVertex(_editingPolygonId!, _selectedVertexIndex!, newPos);
  }
}
