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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.locRead('drawing_saved'))));
    }
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
}
