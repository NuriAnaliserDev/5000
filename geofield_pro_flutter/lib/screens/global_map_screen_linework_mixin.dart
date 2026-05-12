part of 'global_map_screen.dart';

/// Linework bosishi, chiziqlar Tahrir/o‘chirish, slice yakunlash va vertiks —
/// [GlobalMapScreenStateFields] ustidagi mantiq.
mixin GlobalMapLineworkMixin on GlobalMapScreenStateFields {
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

  double _lineHitToleranceMeters(LatLng tap) {
    final z = _mapController.camera.zoom;
    final lat = tap.latitude;
    final metersPerPixel =
        40075016.686 * math.cos(lat * math.pi / 180) / (math.pow(2, z) * 256);
    return (28 * metersPerPixel).clamp(5.0, 150.0);
  }

  Future<void> _confirmDeleteLine(GeologicalLine line) async {
    await MapLineActions.confirmDeleteLine(context, line);
  }

  Future<void> _onGeologicalLineTapped(GeologicalLine line) async {
    await MapLineActions.showLineActions(context, line);
  }

  Future<void> _saveDrawing() async {
    final saved = await MapLineActions.saveDrawing(
      context,
      selectedLineType: _selectedLineType,
      points: List<LatLng>.from(_drawingPoints),
      isCurvedMode: _isCurvedMode,
    );
    if (!saved || !mounted) return;
    setState(() {
      _isDrawingMode = false;
      _drawingPoints.clear();
    });
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

  Future<void> _showAddStructureDialog(LatLng point) async {
    await MapStructureActions.showAddStructureDialog(context, point);
  }
}
