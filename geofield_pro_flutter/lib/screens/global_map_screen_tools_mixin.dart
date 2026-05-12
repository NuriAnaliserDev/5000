part of 'global_map_screen.dart';

mixin GlobalMapToolsMixin on GlobalMapScreenStateFields {
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

  void _openFieldWorkshop() {
    HapticFeedback.selectionClick();
    AppRouter.pushFieldWorkshop(context, initLocation: {
      'lat': _centerLat,
      'lng': _centerLng,
    });
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
        ErrorHandler.show(context, ErrorMapper.map(e));
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
        context.push(AppRouter.analysis);
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
        _isEraserMode = false;
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
      _isEraserMode = false;
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
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
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
}
