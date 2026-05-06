part of 'web_map_screen.dart';

class _WebMapScreenState extends State<WebMapScreen>
    with WebMapScreenFields, WebMapScreenActionsMixin, WebMapScreenMapMixin {
  @override
  void dispose() {
    _zoneNameCtrl.dispose();
    _zoneDescCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boundaries = context.watch<BoundaryService>().boundaries;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    onTypeChanged: (zt) =>
                        setState(() => _selectedZoneType = zt),
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
}
