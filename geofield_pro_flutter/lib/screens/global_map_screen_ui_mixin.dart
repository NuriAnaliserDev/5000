part of 'global_map_screen.dart';

mixin GlobalMapMapUiMixin on GlobalMapToolsMixin {
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
              onAddStation: () {
                AppRouter.pushStation(context);
              },
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
              onSampling: () {
                AppRouter.pushStation(context);
              },
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
}
