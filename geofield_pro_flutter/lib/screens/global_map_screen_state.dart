part of 'global_map_screen.dart';

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
  final List<LatLng> _redoStack = [];
  bool _isEraserMode = false;
  String _selectedLineType = 'fault';
  bool _isCurvedMode = false;
  double _projectionDepth = 0;
  bool _showProjections = false;
  bool _isSnapEnabled = true;

  double _baseLayerOpacity = 1.0;
  double _gisLayerOpacity = 0.6;
  double _drawingLayerOpacity = 1.0;
  bool _showLayerDrawer = false;

  /// Xarita «dala vositalari» radial menyusi ochiq/yopiq.
  bool _mapFieldMenuOpen = false;

  String? _editingPolygonId;
  int? _selectedVertexIndex;
  bool _isVertexEditMode = false;

  bool _isSliceMode = false;

  /// Field Move uslubida: xaritada qo'lda strike/dip belgisi
  bool _isStructurePlaceMode = false;

  /// O‘lchov rejimi: 2 nuqta — masofa, 3+ — yopiq poligon maydoni
  bool _isMeasureMode = false;
  final List<LatLng> _measurePoints = [];
  final List<bool> _workshopChecklist = [false, false, false];

  double _centerLat = 41.2995;
  double _centerLng = 69.2401;

  /// GPS yangilanishi bilan xaritani surib yuritish.
  bool _followGps = false;
  LocationService? _locationForFollow;

  /// Pro maydon: qisqacha tushuntirish (yopguncha).
  bool _workshopInfoBanner = true;

  @override
  void initState() {
    super.initState();
    _initMap();
    _startCompass();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _locationForFollow = context.read<LocationService>();
      _locationForFollow!.addListener(_onGpsForFollow);
      unawaited(context.read<SosService>().syncActiveSosFromServer());
      _checkShowTutorial();
      _startPresenceBroadcast();
      if (widget.fieldWorkshopMode) {
        setState(() => _showLayerDrawer = true);
      }
    });
  }

  void _onGpsForFollow() {
    if (!mounted || !_followGps) {
      return;
    }
    final p = _locationForFollow?.currentPosition;
    if (p == null) {
      return;
    }
    _mapController.move(
      LatLng(p.latitude, p.longitude),
      _mapController.camera.zoom,
    );
  }

  void _startPresenceBroadcast() {
    final settings = context.read<SettingsController>();
    final presence = context.read<PresenceService>();
    presence.startBroadcasting(
      () {
        final pos = context.read<LocationService>().currentPosition;
        return pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : LatLng(_centerLat, _centerLng);
      },
      settings.currentUserName ?? 'Geolog',
      settings.expertMode ? 'Professional' : 'Standard',
    );
  }

  void _checkShowTutorial() {
    if (widget.fieldWorkshopMode) {
      return;
    }
    final settings = context.read<SettingsController>();
    if (settings.hasSeenMapTutorial) return;

    TutorialService.showTutorial(
      context,
      targets: [
        TutorialService.createTarget(
          key: _drawButtonKey,
          identify: "draw_btn",
          title: "Chizish Rejimi",
          description:
              "Bu yerda siz Fault (Uzilmalar), Contact (Kontaklar) va Bedding Trace (Qatlam izlari) chizishingiz mumkin.",
        ),
        TutorialService.createTarget(
          key: _downloadButtonKey,
          identify: "download_btn",
          title: "Oflayn Xaritalar",
          description:
              "Dala sharoitida internet bo'lmaganda ham ishlash uchun xarita hududini yuklab oling.",
        ),
      ],
      onFinish: () => settings.hasSeenMapTutorial = true,
    );
  }

  @override
  void dispose() {
    _locationForFollow?.removeListener(_onGpsForFollow);
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
    final geoLines =
        context.select<GeologicalLineRepository, List<GeologicalLine>>(
      (repo) => repo.getAllLines(),
    );
    final structureAnnotations =
        context.select<MapStructureRepository, List<MapStructureAnnotation>>(
            (r) => r.annotations);
    final trackSvc = context.read<TrackService>();
    final locationSvc = context.read<LocationService>();
    final currentPos = locationSvc.currentPosition;

    LatLng center = widget.initLocation != null
        ? LatLng(widget.initLocation!['lat'], widget.initLocation!['lng'])
        : (currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : (stations.isNotEmpty
                ? LatLng(stations.first.lat, stations.first.lng)
                : const LatLng(41.2995, 69.2401)));

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
                onTap: (tapPosition, point) =>
                    _handleMapTap(point, boundarySvc),
                onSecondaryTap: (tapPosition, point) {
                  if (_isDrawingMode && _drawingPoints.isNotEmpty) {
                    setState(() => _drawingPoints.removeLast());
                  }
                },
                onLongPress: (tapPosition, point) {
                  if (_isDrawingMode && _drawingPoints.isNotEmpty) {
                    setState(() => _drawingPoints.removeLast());
                  }
                },
                onPositionChanged: (pos, hasGesture) {
                  _centerLat = pos.center.latitude;
                  _centerLng = pos.center.longitude;
                  if (hasGesture == true && _followGps) {
                    setState(() => _followGps = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrlTemplate(mapStyle),
                  subdomains: mapTileSubdomains(mapStyle),
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
                if (_isDrawingMode && _drawingPoints.isNotEmpty)
                  MarkerLayer(
                    markers: _drawingPoints
                        .map(
                          (p) => Marker(
                            point: p,
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFFF9800), width: 2),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (_isSliceMode && _drawingPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                          points: _drawingPoints,
                          color: Colors.orange,
                          strokeWidth: 3.0),
                    ],
                  ),
                if (_isMeasureMode && _measurePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _measurePoints,
                        color: Colors.cyanAccent,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                if (_isMeasureMode && _measurePoints.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _measurePoints,
                        color: Colors.cyan.withValues(alpha: 0.12),
                        borderColor: Colors.cyan,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                if (_isVertexEditMode && _editingPolygonId != null)
                  PolylineLayer(
                    polylines: mapVertexEditPolylines(
                      boundaries,
                      editingPolygonId: _editingPolygonId,
                      selectedVertexIndex: _selectedVertexIndex,
                    ),
                  ),
                PolygonLayer(
                  polygons: [
                    ...boundaries
                        .where((b) => b.points.length >= 3)
                        .map<Polygon>((b) => mapPolygonForBoundary(
                            b, currentPos, _gisLayerOpacity)),
                    ...geoLines
                        .where((l) => l.isClosed)
                        .map((l) => mapPolygonForGeologicalLine(l)),
                    if (_isDrawingMode &&
                        _selectedLineType == 'polygon' &&
                        _drawingPoints.length >= 3)
                      Polygon(
                        points: _drawingPoints,
                        color: Color(int.parse(
                                GeologicalLine.defaultColorHex(
                                    _selectedLineType),
                                radix: 16) +
                            0x66000000),
                        borderColor: Colors.transparent,
                        borderStrokeWidth: 0,
                      ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    ...boundaries.where((b) => b.points.length == 2).map(
                          (b) => Polyline(
                            points: b.points,
                            color: b.displayColor.withValues(
                                alpha: math.max(0.75, _gisLayerOpacity)),
                            strokeWidth: 3,
                          ),
                        ),
                  ],
                ),
                MapStructureMarkersLayer(
                  annotations: structureAnnotations,
                  opacity: _drawingLayerOpacity,
                  onMarkerTap: (a) => unawaited(_confirmDeleteStructure(a)),
                ),
                MapStationLayer(
                  stations: stations,
                  onStationTap: (s) =>
                      Navigator.of(context, rootNavigator: true)
                          .pushNamed('/station', arguments: s.key as int?),
                ),
                if (widget.initLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: center,
                        child: const Icon(Icons.pin_drop,
                            color: Colors.redAccent, size: 40),
                      ),
                    ],
                  ),
                const MapTeamPresenceLayer(),
                const MapSosSignalsLayer(),
                _buildUserLocationMarker(currentPos),
              ],
            ),
            if (widget.fieldWorkshopMode) const MapGpsHud(),
            MapLegend(
                stations: stations,
                currentPos: currentPos,
                mapController: _mapController),
            if (widget.fieldWorkshopMode)
              MapTopBar(
                stationsCount: stations.length,
                settings: settings,
                onStylePressed: () => _showMapStyleSelector(context, settings),
                onSearchPressed: _openSearch,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                titleOverride:
                    GeoFieldStrings.of(context)?.field_workshop_title ??
                        'Field workshop',
                secondaryLineOverride:
                    '${settings.currentProject} · ${stations.length} ${context.loc('stations')}',
              )
            else
              MapStitchTopCluster(
                stationsCount: stations.length,
                settings: settings,
                onStylePressed: () => _showMapStyleSelector(context, settings),
                onSearchPressed: _openSearch,
              ),
            if (widget.fieldWorkshopMode && _workshopInfoBanner)
              _buildWorkshopInfoBanner(),
            if (widget.fieldWorkshopMode) _buildFieldWorkshopToolRail(),
            if (currentTrack != null)
              MapLiveTrackStats(track: trackSvc.currentTrack!),
            if (widget.fieldWorkshopMode)
              _buildMapFloatingLayer(currentPos: currentPos)
            else
              _buildStitchMapChrome(currentPos: currentPos),
            MapLineworkControls(
              isDrawingMode: _isDrawingMode,
              selectedLineType: _selectedLineType,
              isCurvedMode: _isCurvedMode,
              isSnapEnabled: _isSnapEnabled,
              drawingPointsCount: _drawingPoints.length,
              drawButtonKey: _drawButtonKey,
              canRedo: _redoStack.isNotEmpty,
              isEraserMode: _isEraserMode,
              suppressIdleSideRail: !widget.fieldWorkshopMode,
              onStartDrawing: _startLineDrawing,
              onLineTypeChanged: (type) =>
                  setState(() => _selectedLineType = type),
              onToggleCurve: () =>
                  setState(() => _isCurvedMode = !_isCurvedMode),
              onToggleSnap: () =>
                  setState(() => _isSnapEnabled = !_isSnapEnabled),
              onUndo: () => setState(() {
                if (_drawingPoints.isNotEmpty) {
                  _redoStack.add(_drawingPoints.removeLast());
                }
              }),
              onRedo: () => setState(() {
                if (_redoStack.isNotEmpty) {
                  _drawingPoints.add(_redoStack.removeLast());
                }
              }),
              onCancel: () => setState(() {
                _isDrawingMode = false;
                _drawingPoints.clear();
                _redoStack.clear();
              }),
              onSave: _saveDrawing,
              onToggleEraser: _toggleEraserMode,
            ),
            MapProjectionControls(
              showProjections: _showProjections,
              projectionDepth: _projectionDepth,
              suppressFloatingToggle: !widget.fieldWorkshopMode,
              onToggleProjections: () =>
                  setState(() => _showProjections = !_showProjections),
              onDepthChanged: (v) => setState(() => _projectionDepth = v),
            ),
            MapLayerDrawer(
              isVisible: _showLayerDrawer,
              baseLayerOpacity: _baseLayerOpacity,
              gisLayerOpacity: _gisLayerOpacity,
              drawingLayerOpacity: _drawingLayerOpacity,
              isVertexEditMode: _isVertexEditMode,
              onToggleDrawer: () =>
                  setState(() => _showLayerDrawer = !_showLayerDrawer),
              onBaseOpacityChanged: (v) =>
                  setState(() => _baseLayerOpacity = v),
              onGisOpacityChanged: (v) => setState(() => _gisOpacityChanged(v)),
              onDrawingOpacityChanged: (v) =>
                  setState(() => _drawingLayerOpacity = v),
              onToggleVertexEdit: () => setState(() {
                _isVertexEditMode = !_isVertexEditMode;
                if (!_isVertexEditMode) {
                  _editingPolygonId = null;
                  _selectedVertexIndex = null;
                }
              }),
              onImportGis: _importGisFromMap,
              onOpenExportArchive: () => MainTabNavigation.openArchive(context),
              onExportGeoJson: _exportMapGeoJson,
              mapLayersToggleTutorialKey: _downloadButtonKey,
            ),
            if (_isDrawingMode)
              Positioned(
                left: 8,
                right: 8,
                bottom: 80,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      GeoFieldStrings.of(context)?.map_gesture_undo_hint ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, height: 1.3),
                    ),
                  ),
                ),
              ),
            if (_isStructurePlaceMode)
              Positioned(
                left: 8,
                right: 8,
                bottom: 80,
                child: Material(
                  color: Colors.amber.shade900.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      GeoFieldStrings.of(context)?.map_structure_mode_hint ??
                          '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, height: 1.3),
                    ),
                  ),
                ),
              ),
            if (_isMeasureMode) _buildMeasureStatsPanel(),
          ],
        ),
      ),
      bottomNavigationBar: widget.fieldWorkshopMode
          ? null
          : (widget.embedded
              ? null
              : const AppBottomNavBar(activeRoute: '/map')),
    );
  }

  /// Pro maydon: qatlam, GIS, kesim, struktura, chizim, proyeksiya — tez qo‘l panel.
  /// Dala rejimi: faqat tez-tez kerak bo‘lgan 3 + [MapProToolsScreen] kirishi.
  /// Qolganlari takrorlanmasin — bitta Pro ro‘yxatida.
  Widget _buildFieldWorkshopToolRail() {
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }
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
                onPressed: () => setState(() => _showLayerDrawer = true),
                icon: const Icon(Icons.layers, color: Color(0xFF1976D2)),
              ),
              IconButton(
                tooltip: s.map_layer_import_gis,
                onPressed: _importGisFromMap,
                icon: const Icon(Icons.file_upload, color: Color(0xFF388E3C)),
              ),
              IconButton(
                tooltip: context.loc('layer_drawings'),
                onPressed: _workshopStartDrawing,
                icon: Icon(
                  Icons.draw,
                  color: _isDrawingMode
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF5D4037),
                ),
              ),
              const Divider(height: 1),
              IconButton(
                tooltip: s.map_pro_tools_title,
                onPressed: _openMapProTools,
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

  void _workshopStartDrawing() {
    _startLineDrawing();
  }

  void _toggleEraserMode() {
    setState(() {
      _isEraserMode = !_isEraserMode;
      if (_isEraserMode) {
        _isDrawingMode = false;
        _isSliceMode = false;
        _isStructurePlaceMode = false;
        _drawingPoints.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.loc('map_eraser_hint')),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _startLineDrawing() {
    setState(() {
      _mapFieldMenuOpen = false;
      _isMeasureMode = false;
      _measurePoints.clear();
      _isDrawingMode = true;
      _isSliceMode = false;
      _isStructurePlaceMode = false;
      _isEraserMode = false;
      _drawingPoints.clear();
      _redoStack.clear();
    });
  }

  Future<void> _toggleMapTracking() async {
    final trackSvc = context.read<TrackService>();
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    if (trackSvc.isTracking) {
      await trackSvc.stopTracking();
      return;
    }
    final name = 'Trek-${DateTime.now().toIso8601String().substring(0, 19)}'
        .replaceAll(':', '.');
    await trackSvc.startTracking(name);
    if (!mounted) {
      return;
    }
    if (!trackSvc.isTracking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.track_start_failed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.tracking_started_snack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStitchMapChrome({required dynamic currentPos}) {
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }
    final hideSideRails = _isDrawingMode || _isStructurePlaceMode;
    final bottomInset = AppBottomNavBar.overlayClearanceAboveNav(context);
    final pad = MediaQuery.paddingOf(context);
    // MapStitchTopCluster osti: qidiruv + GPS pill — dala menyusi shu yonidan ochiladi.
    final mapFieldHubTop = pad.top + 8 + 58 + 8 + 44 + 6;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_mapFieldMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _mapFieldMenuOpen = false),
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        if (!hideSideRails)
          Positioned(
            right: 6,
            top: mapFieldHubTop,
            child: MapStitchMapHub(
              anchorTop: true,
              menuOpen: _mapFieldMenuOpen,
              onMenuOpenChanged: (v) => setState(() => _mapFieldMenuOpen = v),
              drawTutorialKey: _drawButtonKey,
              followGps: _followGps,
              onOpenProTools: _openMapProTools,
              onDraw: _startLineDrawing,
              onAddStation: () => Navigator.of(context, rootNavigator: true)
                  .pushNamed('/station'),
              onFollowToggle: () {
                setState(() {
                  _followGps = !_followGps;
                  _mapFieldMenuOpen = false;
                });
                if (_followGps) {
                  HapticFeedback.selectionClick();
                  _goToMyLocation(currentPos);
                }
              },
              onMyLocation: () => _goToMyLocation(currentPos),
              onStrikeDip: _toggleStructureMode,
              onSampling: () => Navigator.of(context, rootNavigator: true)
                  .pushNamed('/station'),
              onFieldNotes: () => MainTabNavigation.openCamera(context),
              onProjectLayers: () => setState(() {
                _mapFieldMenuOpen = false;
                _showLayerDrawer = true;
              }),
              onToggleTrack: _toggleMapTracking,
            ),
          ),
        Positioned(
          left: 8,
          bottom: bottomInset + 24,
          child: const MapSosButton(),
        ),
        if (hideSideRails)
          Positioned(
            left: 12,
            bottom: bottomInset + 120,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              color: _isStructurePlaceMode
                  ? Colors.amber.shade800
                  : const Color(0xFF1A2028),
              child: IconButton(
                tooltip: s.map_structure_mode_tooltip,
                onPressed: _toggleStructureMode,
                icon: Icon(
                  Icons.architecture,
                  color: _isStructurePlaceMode
                      ? Colors.white
                      : Colors.amber.shade200,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleMeasureMode() {
    setState(() {
      _isMeasureMode = !_isMeasureMode;
      if (_isMeasureMode) {
        _isDrawingMode = false;
        _isSliceMode = false;
        _isStructurePlaceMode = false;
        _isEraserMode = false;
        _drawingPoints = [];
        _redoStack.clear();
        _measurePoints.clear();
      } else {
        _measurePoints.clear();
      }
    });
    if (_isMeasureMode && mounted) {
      final h = GeoFieldStrings.of(context)?.map_measure_hint;
      if (h != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(h),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildWorkshopInfoBanner() {
    final s = GeoFieldStrings.of(context);
    if (s == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Positioned(
      top: 64,
      left: 10,
      right: 10,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        color: t.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.checklist_rtl, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.field_workshop_checklist,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        setState(() => _workshopInfoBanner = false),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                s.field_workshop_banner,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      t.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              CheckboxListTile(
                value: _workshopChecklist[0],
                onChanged: (v) =>
                    setState(() => _workshopChecklist[0] = v ?? false),
                title: Text(s.field_workshop_ch1,
                    style: const TextStyle(fontSize: 11)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _workshopChecklist[1],
                onChanged: (v) =>
                    setState(() => _workshopChecklist[1] = v ?? false),
                title: Text(s.field_workshop_ch2,
                    style: const TextStyle(fontSize: 11)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _workshopChecklist[2],
                onChanged: (v) =>
                    setState(() => _workshopChecklist[2] = v ?? false),
                title: Text(s.field_workshop_ch3,
                    style: const TextStyle(fontSize: 11)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFieldWorkshop() {
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRouter.fieldWorkshop,
      arguments: <String, dynamic>{
        'lat': _centerLat,
        'lng': _centerLng,
      },
    );
  }

  Widget _buildMeasureStatsPanel() {
    final s = GeoFieldStrings.of(context);
    final m = _measurePoints;
    var line = '';
    if (m.length >= 2) {
      var len = 0.0;
      for (var i = 1; i < m.length; i++) {
        len += MapGeodesy.distanceMeters(m[i - 1], m[i]);
      }
      line += 'Σ ${(len).toStringAsFixed(1)} m';
      final seg = MapGeodesy.distanceMeters(m[m.length - 2], m[m.length - 1]);
      line += '  |  so‘nggi: ${seg.toStringAsFixed(1)} m';
      if (m.length >= 2) {
        line +=
            '  |  ${s?.map_measure_bearing ?? "Brg"}: ${MapGeodesy.bearingDeg(m[m.length - 2], m[m.length - 1]).toStringAsFixed(1)}°';
      }
      if (m.length >= 3) {
        line +=
            '  |  ${s?.map_measure_angle ?? "∠"}: ${MapGeodesy.angleAtB(m[m.length - 3], m[m.length - 2], m[m.length - 1]).toStringAsFixed(1)}°';
      }
    }
    if (m.length >= 3) {
      final area = SpatialCalculator.calculateArea(m);
      line +=
          '  |  S ≈ ${(area / 1e6).toStringAsFixed(3)} km² (≈${area.toStringAsFixed(0)} m²)';
      line +=
          '  |  P: ${SpatialCalculator.calculatePerimeter(m).toStringAsFixed(0)} m';
    }
    return Positioned(
      left: 8,
      right: 8,
      bottom: 80,
      child: Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s?.map_measure_mode ?? 'Measure',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              if (line.isNotEmpty)
                Text(
                  line,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, height: 1.2),
                )
              else
                Text(
                  s?.map_measure_hint ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  setState(() {
                    _measurePoints.clear();
                  });
                },
                child: Text(
                  s?.map_measure_clear ?? 'Clear',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _gisOpacityChanged(double v) => _gisLayerOpacity = v;

  Future<void> _importGisFromMap() async {
    final boundary = context.read<BoundaryService>();
    final s = GeoFieldStrings.of(context);
    try {
      final ok = await showGisImportPrecheckDialog(context);
      if (!ok || !mounted) return;
      final pos = context.read<LocationService>().currentPosition;
      final center = _mapController.camera.center;
      final r = await boundary.importFileFromWeb(
        hintLatitude: pos?.latitude ?? center.latitude,
        hintLongitude: pos?.longitude ?? center.longitude,
      );
      if (!mounted) return;
      if (r == null) {
        return;
      }
      if (r.fitPoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(r.fitPoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ),
        );
      }
      if (s != null) {
        showGisImportResultSnackbar(context, s, r);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// Pro vositalar ekranidan so‘ng amallarni bajarish.
  void _applyMapProToolResult(MapProToolAction a) {
    switch (a) {
      case MapProToolAction.openLayerDrawer:
        setState(() => _showLayerDrawer = true);
        break;
      case MapProToolAction.importGis:
        unawaited(_importGisFromMap());
        break;
      case MapProToolAction.measure:
        _toggleMeasureMode();
        break;
      case MapProToolAction.slice:
        _toggleSliceMode();
        break;
      case MapProToolAction.structure:
        _toggleStructureMode();
        break;
      case MapProToolAction.startDrawing:
        _workshopStartDrawing();
        break;
      case MapProToolAction.toggleEraser:
        _toggleEraserMode();
        break;
      case MapProToolAction.openFieldWorkshop:
        _openFieldWorkshop();
        break;
      case MapProToolAction.threeD:
        final c = _mapController.camera.center;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (ctx) => ThreeDViewerScreen(centerPoint: c),
          ),
        );
        break;
      case MapProToolAction.stereonet:
        Navigator.of(context, rootNavigator: true)
            .pushNamed(AppRouter.analysis);
        break;
      case MapProToolAction.copyUtm:
        _copyUtmCenterToClipboard();
        break;
      case MapProToolAction.centerElevation:
        unawaited(_showMapCenterElevation());
        break;
      case MapProToolAction.exportGeojson:
        unawaited(_exportMapGeoJson());
        break;
      case MapProToolAction.toggleProjection:
        setState(() => _showProjections = !_showProjections);
        break;
    }
  }

  Future<void> _openMapProTools() async {
    if (!mounted) {
      return;
    }
    HapticFeedback.selectionClick();
    final action = await Navigator.of(context).push<MapProToolAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => const MapProToolsScreen(),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    _applyMapProToolResult(action);
  }

  /// Barcha suzuvchi tugmalar — bitta [DraggableFabLayer].
  Widget _buildMapFloatingLayer({required dynamic currentPos}) {
    // Faqat chizim / qo‘lda struktura: chizim paneli bilan to‘qnashadigan
    // qo‘shimcha yon FABlarni yig‘amiz. Kesim va o‘lchovda to‘liq to‘plam
    // ko‘rinadi.
    final hideSideFabsForLineUi = _isDrawingMode || _isStructurePlaceMode;
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }

    Widget? structureFab;
    if (hideSideFabsForLineUi) {
      structureFab = DraggableFab(
        key: const ValueKey('map_fab_structure'),
        defaultOffset: OverlayFabLayout.mapStructure,
        size: OverlayFabLayout.mapStructureSize,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: _isStructurePlaceMode
              ? Colors.amber.shade800
              : const Color(0xFF1A2028),
          child: IconButton(
            tooltip: s.map_structure_mode_tooltip,
            onPressed: _toggleStructureMode,
            icon: Icon(
              Icons.architecture,
              color:
                  _isStructurePlaceMode ? Colors.white : Colors.amber.shade200,
            ),
          ),
        ),
      );
    }

    Widget? proFab;
    if (!widget.fieldWorkshopMode && !hideSideFabsForLineUi) {
      proFab = DraggableFab(
        key: const ValueKey('map_fab_pro'),
        defaultOffset: OverlayFabLayout.mapProTools,
        size: OverlayFabLayout.mapProToolsSize,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF0D47A1),
          child: IconButton(
            tooltip: s.map_pro_tools_title,
            onPressed: _openMapProTools,
            icon: const Icon(
              Icons.workspace_premium,
              color: Color(0xFFFFD54F),
            ),
          ),
        ),
      );
    }

    return DraggableFabLayer(
      children: [
        if (structureFab != null) structureFab,
        if (proFab != null) proFab,
        DraggableFab(
          key: const ValueKey('map_fab_sos'),
          defaultOffset: OverlayFabLayout.mapSos,
          size: OverlayFabLayout.mapSosSize,
          unconstrained: true,
          child: const MapSosButton(),
        ),
        const DraggableFab(
          key: ValueKey('map_fab_track'),
          defaultOffset: OverlayFabLayout.mapTrack,
          size: OverlayFabLayout.mapTrackSize,
          child: MapTrackFab(),
        ),
        DraggableFab(
          key: const ValueKey('map_fab_my_location'),
          defaultOffset: OverlayFabLayout.mapMyLocation,
          size: OverlayFabLayout.mapMyLocationSize,
          child: Tooltip(
            message: context.loc('map_my_location'),
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              backgroundColor: Colors.white,
              onPressed: () => _goToMyLocation(currentPos),
              child: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
            ),
          ),
        ),
        DraggableFab(
          key: const ValueKey('map_fab_follow_gps'),
          defaultOffset: OverlayFabLayout.mapFollowGps,
          size: OverlayFabLayout.mapFollowGpsSize,
          child: Tooltip(
            message: context.loc('map_follow_gps'),
            child: FloatingActionButton.small(
              heroTag: 'map_follow_gps_fab',
              backgroundColor:
                  _followGps ? const Color(0xFF1976D2) : Colors.white,
              onPressed: () {
                setState(() {
                  _followGps = !_followGps;
                });
                if (_followGps) {
                  HapticFeedback.selectionClick();
                  _goToMyLocation(currentPos);
                }
              },
              child: Icon(
                _followGps
                    ? Icons.navigation
                    : Icons.compass_calibration_outlined,
                color: _followGps ? Colors.white : const Color(0xFF1976D2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleStructureMode() {
    final s = GeoFieldStrings.of(context);
    setState(() {
      _mapFieldMenuOpen = false;
      _isMeasureMode = false;
      _measurePoints.clear();
      _isStructurePlaceMode = !_isStructurePlaceMode;
      if (_isStructurePlaceMode) {
        _isDrawingMode = false;
        _isSliceMode = false;
        _drawingPoints = [];
      }
    });
    if (_isStructurePlaceMode) {
      final h = s?.map_structure_mode_hint;
      if (h != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(h),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _toggleSliceMode() {
    setState(() {
      _isMeasureMode = false;
      _measurePoints.clear();
      _isSliceMode = !_isSliceMode;
      _isDrawingMode = false;
      _isStructurePlaceMode = false;
      _drawingPoints = [];
    });
    if (_isSliceMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('select_two_points'))),
      );
    }
  }

  void _goToMyLocation(dynamic pos) async {
    LatLng? target;
    if (pos != null) {
      target = LatLng(pos.latitude, pos.longitude);
    } else {
      final loc = context.read<LocationService>();
      final p = loc.currentPosition;
      if (p != null) {
        target = LatLng(p.latitude, p.longitude);
      }
    }
    if (target == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locRead('gps_not_locked')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _mapController.move(target, math.max(_mapController.camera.zoom, 15));
    HapticFeedback.selectionClick();
  }

  Future<void> _openSearch() async {
    final result = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: MapSearchSheet(),
      ),
    );
    if (result != null && mounted) {
      _mapController.move(result, math.max(_mapController.camera.zoom, 13));
    }
  }

  void _handleMapTap(LatLng point, BoundaryService boundarySvc) {
    if (_isEraserMode) {
      _eraseNear(point);
      return;
    }
    if (_isMeasureMode) {
      setState(() => _measurePoints.add(point));
      HapticFeedback.selectionClick();
      return;
    }
    if (_isVertexEditMode && _editingPolygonId != null) {
      _moveVertex(point);
    } else if (_isVertexEditMode && _editingPolygonId == null) {
      final picked = boundarySvc.getBoundaryAt(point);
      if (picked != null) {
        setState(() {
          _editingPolygonId = picked.id;
          _selectedVertexIndex = 0;
        });
      }
    } else if (_isDrawingMode) {
      LatLng finalPoint = point;
      if (_isSnapEnabled) {
        final stationRepo = context.read<StationRepository>();
        final lineRepo = context.read<GeologicalLineRepository>();
        final settings = context.read<SettingsController>();
        final candidates = LineworkUtils.buildSnapCandidatePoints(
          stationPoints:
              stationRepo.stations.map((s) => LatLng(s.lat, s.lng)).toList(),
          lines: lineRepo.lines,
          boundaries: boundarySvc.boundaries,
          focus: point,
          snapGridMeters: settings.snapToGridMeters,
        );
        final snapped = LineworkUtils.findNearestSnapPoint(
          point,
          candidates,
        );
        if (snapped != null) {
          finalPoint = snapped;
          HapticFeedback.lightImpact();
        }
      }
      setState(() {
        _drawingPoints.add(finalPoint);
        _redoStack.clear();
      });
      if (!mounted) return;
      if (_drawingPoints.length == 1) {
        final h = GeoFieldStrings.of(context)?.draw_first_point_hint;
        if (h != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(h),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else if (_isSliceMode) {
      setState(() => _drawingPoints.add(point));
      if (_drawingPoints.length == 2) _finalizeSlice();
    } else if (_isStructurePlaceMode) {
      unawaited(_showAddStructureDialog(point));
    } else {
      final tol = _lineHitToleranceMeters(point);
      final lineRepo = context.read<GeologicalLineRepository>();
      final hit = LineworkUtils.findGeologicalLineNear(
        point,
        lineRepo.lines,
        maxDistanceMeters: tol,
      );
      if (hit != null) {
        unawaited(_onGeologicalLineTapped(hit));
      }
    }
  }

  /// Eraser rejimida xarita bosilganda eng yaqin geologik chiziqni topib,
  /// foydalanuvchidan tasdiqlab o‘chiradi.
  Future<void> _eraseNear(LatLng point) async {
    final lineRepo = context.read<GeologicalLineRepository>();
    final tol = _lineHitToleranceMeters(point);
    final hit = LineworkUtils.findGeologicalLineNear(
      point,
      lineRepo.lines,
      maxDistanceMeters: tol,
    );
    if (hit != null) {
      await _confirmDeleteLine(hit);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yaqin atrofda chiziq yo‘q'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Chiziq «bosish» radiusi — ekranda ~28px atrofida (masshtabga bog‘liq).
  double _lineHitToleranceMeters(LatLng tap) {
    final z = _mapController.camera.zoom;
    final lat = tap.latitude;
    final metersPerPixel =
        40075016.686 * math.cos(lat * math.pi / 180) / (math.pow(2, z) * 256);
    return (28 * metersPerPixel).clamp(5.0, 150.0);
  }

  Future<void> _confirmDeleteLine(GeologicalLine line) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.name),
        content: Text(s.map_tap_line_delete_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(s.delete_confirm_btn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<GeologicalLineRepository>().deleteLine(line.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.map_line_deleted_snack),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onGeologicalLineTapped(GeologicalLine line) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(s.line_action_edit),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(s.delete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(s.cancel),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _showLinePropertyEditor(line);
    } else if (action == 'delete') {
      await _confirmDeleteLine(line);
    }
  }

  Future<void> _showLinePropertyEditor(GeologicalLine line) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    const types = <String>[
      'fault',
      'contact',
      'bedding_trace',
      'fold_axis',
      'polygon',
      'other',
    ];
    final nameCtrl = TextEditingController(text: line.name);
    final notesCtrl = TextEditingController(text: line.notes ?? '');
    var lineType = line.lineType;
    if (!types.contains(lineType)) lineType = 'other';
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setL) {
          return AlertDialog(
            title: Text(s.line_property_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: s.line_property_name),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Type'),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: lineType,
                      items: types
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(GeologicalLine.localizedName(e)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setL(() => lineType = v ?? lineType),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration:
                        InputDecoration(labelText: s.line_property_notes),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.save),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    final n = notesCtrl.text.trim();
    final updated = GeologicalLine(
      id: line.id,
      name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : line.name,
      lineType: lineType,
      lats: line.lats,
      lngs: line.lngs,
      date: line.date,
      colorHex: line.colorHex,
      project: line.project,
      notes: n.isEmpty ? null : n,
      isClosed: line.isClosed,
      strokeWidth: line.strokeWidth,
      isDashed: line.isDashed,
      isCurved: line.isCurved,
      controlLats: line.controlLats,
      controlLngs: line.controlLngs,
    );
    await context.read<GeologicalLineRepository>().updateLine(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locRead('success_saved')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyUtmCenterToClipboard() {
    final p = LatLng(_centerLat, _centerLng);
    final t = UtmWgs84.formatUtm(p);
    Clipboard.setData(ClipboardData(text: t));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showMapCenterElevation() async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    final c = _mapController.camera.center;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.elevation_lookup_progress),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    final m = await ElevationService.fetchElevationMeters(c);
    if (!mounted) return;
    if (m == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.elevation_lookup_failed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.elevation_meters_result(m.toStringAsFixed(1)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportMapGeoJson() async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    try {
      final lines = context.read<GeologicalLineRepository>().getAllLines();
      final bounds = context.read<BoundaryService>().boundaries;
      final text = GisGeoJsonExport.buildString(
        lines: lines,
        boundaries: bounds,
      );
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.map_export_geojson),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.geojson',
      );
      await f.writeAsString(text);
      await Share.shareXFiles([XFile(f.path)], text: s.map_export_geojson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.map_error_prefix}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddStructureDialog(LatLng point) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    const types = <String>[
      'bedding',
      'cleavage',
      'lineation',
      'joint',
      'contact',
      'fault',
      'other'
    ];
    var selectedType = 'bedding';
    final strikeCtrl = TextEditingController(text: '0');
    final dipCtrl = TextEditingController(text: '45');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(s.map_structure_add_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: strikeCtrl,
                    decoration: InputDecoration(
                        labelText: s.map_structure_strike_label),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dipCtrl,
                    decoration:
                        InputDecoration(labelText: s.map_structure_dip_label),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.map_structure_type_label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: types.map((t) {
                      final selected = selectedType == t;
                      return FilterChip(
                        label: Text(
                          Measurement(
                            type: t,
                            strike: 0,
                            dip: 0,
                            dipDirection: 0,
                            capturedAt: DateTime.now(),
                          ).localizedType,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: selected,
                        onSelected: (_) => setLocal(() => selectedType = t),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.save_label),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    var strike = double.tryParse(strikeCtrl.text.replaceAll(',', '.')) ?? 0;
    var dip = double.tryParse(dipCtrl.text.replaceAll(',', '.')) ?? 0;
    strike = strike % 360;
    if (strike < 0) strike += 360;
    dip = dip.clamp(0, 90);
    final a = MapStructureAnnotation(
      id: const Uuid().v4(),
      lat: point.latitude,
      lng: point.longitude,
      strike: strike,
      dip: dip,
      structureType: selectedType,
      createdAt: DateTime.now(),
    );
    await context.read<MapStructureRepository>().addAnnotation(a);
  }

  Future<void> _confirmDeleteStructure(MapStructureAnnotation a) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            '${a.strike.toStringAsFixed(0)}° / ${a.dip.toStringAsFixed(0)}°'),
        content: Text(s.map_structure_delete_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(s.delete_confirm_btn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<MapStructureRepository>().deleteAnnotation(a.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.map_structure_deleted_snack),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUserLocationMarker(dynamic currentPos) {
    if (currentPos == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          width: 64,
          height: 64,
          point: LatLng(currentPos.latitude, currentPos.longitude),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightBlueAccent.withValues(alpha: 0.18))),
              Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.lightBlueAccent)),
              ValueListenableBuilder<double?>(
                valueListenable: _headingNotifier,
                builder: (context, heading, child) {
                  if (heading == null) return const SizedBox.shrink();
                  return Transform.rotate(
                    angle: heading * math.pi / 180,
                    child: Transform.translate(
                        offset: const Offset(0, -18),
                        child: const Icon(Icons.navigation,
                            color: Colors.blueAccent, size: 22)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapStyleSelector(
      BuildContext context, SettingsController settings) {
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

  Widget _styleTile(BuildContext context, SettingsController settings,
      String style, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(context.loc(style)),
      selected: settings.mapStyle == style,
      onTap: () {
        settings.mapStyle = style;
        Navigator.pop(context);
      },
    );
  }

  Future<void> _saveDrawing() async {
    final nameCtrl = TextEditingController(
        text: '${GeologicalLine.localizedName(_selectedLineType)} 1');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('save_drawing_title')),
        content: TextField(
            controller: nameCtrl,
            decoration:
                InputDecoration(labelText: context.loc('drawing_name'))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.loc('cancel'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.loc('save_label'))),
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
    setState(() {
      _isDrawingMode = false;
      _drawingPoints.clear();
    });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.locRead('drawing_saved'))));
  }

  void _finalizeSlice() {
    final start = _drawingPoints[0];
    final end = _drawingPoints[1];
    setState(() {
      _isSliceMode = false;
      _drawingPoints = [];
    });
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => CrossSectionScreen(start: start, end: end)));
  }

  void _moveVertex(LatLng newPos) {
    if (_editingPolygonId == null || _selectedVertexIndex == null) return;
    context
        .read<BoundaryService>()
        .updatePolygonVertex(_editingPolygonId!, _selectedVertexIndex!, newPos);
  }
}
