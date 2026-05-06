part of 'global_map_screen.dart';

class _GlobalMapScreenState extends State<GlobalMapScreen>
    with GlobalMapScreenStateFields,
         GlobalMapLineworkMixin,
         GlobalMapPresenceCompassMixin,
         GlobalMapToolsMixin,
         GlobalMapMapUiMixin {
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

  @override
  void dispose() {
    _locationForFollow?.removeListener(_onGpsForFollow);
    _compassSub?.cancel();
    _headingNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PERFORMANCE FIX: Removed all context.select at the top level.
    // Instead, wrapped individual FlutterMap layers with Consumer/Selector.
    // This entirely prevents the heavy FlutterMap from rebuilding when a single station or GPS point updates.
    final locationSvc = context.read<LocationService>();
    final currentPos = locationSvc.currentPosition;
    final boundarySvc = context.read<BoundaryService>();

    LatLng center = widget.initLocation != null
        ? LatLng(widget.initLocation!['lat'], widget.initLocation!['lng'])
        : (currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : const LatLng(41.2995, 69.2401));

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
                Selector<SettingsController, String>(
                  selector: (_, s) => s.mapStyle,
                  builder: (context, mapStyle, _) => TileLayer(
                    urlTemplate: mapTileUrlTemplate(mapStyle),
                    subdomains: mapTileSubdomains(mapStyle),
                    userAgentPackageName: 'com.geofield.pro.flutter',
                    maxNativeZoom: mapStyle == 'satellite' ? 17 : 15,
                    maxZoom: 18,
                    tileProvider: _tileProvider,
                  ),
                ),
                Consumer<TrackService>(
                  builder: (context, track, _) => MapTrackLayer(
                    storedTracks: track.storedTracks,
                    currentTrack: track.currentTrack,
                    gisLayerOpacity: _gisLayerOpacity,
                  ),
                ),
                Consumer<GeologicalLineRepository>(
                  builder: (context, geoRepo, _) => MapLineworkLayer(
                    geoLines: geoRepo.getAllLines(),
                    isDrawingMode: _isDrawingMode,
                    drawingPoints: _drawingPoints,
                    selectedLineType: _selectedLineType,
                    isCurvedMode: _isCurvedMode,
                  ),
                ),
                if (_isDrawingMode && _drawingPoints.isNotEmpty)
                  MarkerLayer(
                    markers: _drawingPoints
                        .map((p) => Marker(
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
                            ))
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
                Consumer<BoundaryService>(
                  builder: (context, boundaryService, _) {
                    final boundaries = boundaryService.boundaries;
                    return Stack(
                      children: [
                        if (_isVertexEditMode && _editingPolygonId != null)
                          PolylineLayer(
                            polylines: mapVertexEditPolylines(
                              boundaries,
                              editingPolygonId: _editingPolygonId,
                              selectedVertexIndex: _selectedVertexIndex,
                            ),
                          ),
                        Consumer<GeologicalLineRepository>(
                          builder: (context, geoRepo, _) {
                            final geoLines = geoRepo.getAllLines();
                            return PolygonLayer(
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
                            );
                          },
                        ),
                        PolylineLayer(
                          polylines: [
                            ...boundaries
                                .where((b) => b.points.length == 2)
                                .map(
                                  (b) => Polyline(
                                    points: b.points,
                                    color: b.displayColor.withValues(
                                        alpha:
                                            math.max(0.75, _gisLayerOpacity)),
                                    strokeWidth: 3,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                Consumer<MapStructureRepository>(
                  builder: (context, structureRepo, _) =>
                      MapStructureMarkersLayer(
                    annotations: structureRepo.annotations,
                    opacity: _drawingLayerOpacity,
                    onMarkerTap: (a) => unawaited(_confirmDeleteStructure(a)),
                  ),
                ),
                Consumer<StationRepository>(
                  builder: (context, stationRepo, _) => MapStationLayer(
                    stations: stationRepo.stations,
                    onStationTap: (s) {
                      AppRouter.pushStation(context, stationId: s.key as int?);
                    },
                  ),
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
                Consumer<LocationService>(
                  builder: (context, loc, _) =>
                      _buildUserLocationMarker(loc.currentPosition),
                ),
              ],
            ),
            if (widget.fieldWorkshopMode) const MapGpsHud(),
            Consumer<StationRepository>(
              builder: (context, stationRepo, _) => Consumer<LocationService>(
                builder: (context, locSvc, _) => MapLegend(
                  stations: stationRepo.stations,
                  currentPos: locSvc.currentPosition,
                  mapController: _mapController,
                ),
              ),
            ),
            if (widget.fieldWorkshopMode)
              Consumer2<StationRepository, SettingsController>(
                builder: (context, stationRepo, settingsController, _) =>
                    MapTopBar(
                  stationsCount: stationRepo.stations.length,
                  settings: settingsController,
                  onStylePressed: () =>
                      _showMapStyleSelector(context, settingsController),
                  onSearchPressed: _openSearch,
                  leading: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  titleOverride:
                      GeoFieldStrings.of(context)?.field_workshop_title ??
                          'Field workshop',
                  secondaryLineOverride:
                      '${settingsController.currentProject} · ${stationRepo.stations.length} ${context.loc('stations')}',
                ),
              )
            else
              Consumer2<StationRepository, SettingsController>(
                builder: (context, stationRepo, settingsController, _) =>
                    MapStitchTopCluster(
                  stationsCount: stationRepo.stations.length,
                  settings: settingsController,
                  onStylePressed: () =>
                      _showMapStyleSelector(context, settingsController),
                  onSearchPressed: _openSearch,
                ),
              ),
            if (widget.fieldWorkshopMode && _workshopInfoBanner)
              _buildWorkshopInfoBanner(),
            if (widget.fieldWorkshopMode) _buildFieldWorkshopToolRail(),
            Consumer<TrackService>(
              builder: (context, track, _) {
                if (track.currentTrack != null) {
                  return MapLiveTrackStats(track: track.currentTrack!);
                }
                return const SizedBox.shrink();
              },
            ),
            Consumer<LocationService>(
              builder: (context, locSvc, _) {
                if (widget.fieldWorkshopMode) {
                  return _buildMapFloatingLayer(
                      currentPos: locSvc.currentPosition);
                } else {
                  return _buildStitchMapChrome(
                      currentPos: locSvc.currentPosition);
                }
              },
            ),
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
}
