part of '../archive_screen.dart';

class _ArchiveScreenState extends State<ArchiveScreen>
    with
        SingleTickerProviderStateMixin,
        ArchiveScreenFields,
        ArchiveScreenActionsMixin {
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isSelectionMode = false;
          _isTrackSelectionMode = false;
          _selectedStationKeys.clear();
          _selectedTrackKeys.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    final bool isStationsTab = _tabController.index == 0;
    final bool isSelecting =
        isStationsTab ? _isSelectionMode : _isTrackSelectionMode;
    final int selCount =
        isStationsTab ? _selectedStationKeys.length : _selectedTrackKeys.length;

    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        backgroundColor: surf,
        title: isSelecting
            ? Text('$selCount ${context.loc('selected_label')}')
            : Text(context.loc('archive')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1976D2),
          labelColor: const Color(0xFF1976D2),
          tabs: [
            Tab(text: context.loc('stations')),
            Tab(text: context.loc('routes')),
          ],
        ),
        actions: isSelecting
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: context.loc('delete'),
                  onPressed: () {
                    if (isStationsTab) {
                      archiveDeleteSelectedStations(context,
                          selectedKeys: Set<int>.from(_selectedStationKeys),
                          onCleared: () => setState(() {
                                _isSelectionMode = false;
                                _selectedStationKeys.clear();
                              }));
                    } else {
                      archiveDeleteSelectedTracks(context,
                          selectedKeys: Set<int>.from(_selectedTrackKeys),
                          onCleared: () => setState(() {
                                _isTrackSelectionMode = false;
                                _selectedTrackKeys.clear();
                              }));
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      if (isStationsTab) {
                        final repo = context.read<StationRepository>();
                        for (final s in repo.stations) {
                          _selectedStationKeys.add(s.key as int);
                        }
                      } else {
                        final tRepo = context.read<TrackService>();
                        for (final t in tRepo.storedTracks) {
                          _selectedTrackKeys.add(t.key as int);
                        }
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _isTrackSelectionMode = false;
                    _selectedStationKeys.clear();
                    _selectedTrackKeys.clear();
                  }),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: context.loc('filter'),
                  onPressed: _showFilterDialog,
                )
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: '${context.loc('search')}...',
                      isDense: true,
                      filled: true,
                      fillColor: onSurf.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedProject != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_selectedProject!,
                          style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _selectedProject = null),
                      avatar: const Icon(Icons.close, size: 14),
                      backgroundColor:
                          const Color(0xFF1976D2).withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: AppBottomNavBar.overlayClearanceAboveNav(context)),
              child: TabBarView(
                controller: _tabController,
                children: [
                  ArchiveStationsTab(
                    searchQuery: _searchQuery,
                    selectedProject: _selectedProject,
                    isSelectionMode: _isSelectionMode,
                    selectedStationKeys: _selectedStationKeys,
                    onSelectionChanged: (key, val) => setState(() => val
                        ? _selectedStationKeys.add(key)
                        : _selectedStationKeys.remove(key)),
                    onStationTap: (key) {
                      if (_isSelectionMode) {
                        setState(() => _selectedStationKeys.contains(key)
                            ? _selectedStationKeys.remove(key)
                            : _selectedStationKeys.add(key));
                      } else {
                        AppRouter.pushStation(context, stationId: key);
                      }
                    },
                    onStationLongPress: (key) {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedStationKeys.add(key);
                        });
                      }
                    },
                    onDeleteStation: (s) => archiveDeleteStationWithUndo(
                        context, context.read<StationRepository>(), s),
                  ),
                  ArchiveTracksTab(
                    searchQuery: _searchQuery,
                    isSelectionMode: _isTrackSelectionMode,
                    selectedTrackKeys: _selectedTrackKeys,
                    onSelectionChanged: (key, val) => setState(() => val
                        ? _selectedTrackKeys.add(key)
                        : _selectedTrackKeys.remove(key)),
                    onTrackTap: (key) {
                      if (_isTrackSelectionMode) {
                        setState(() => _selectedTrackKeys.contains(key)
                            ? _selectedTrackKeys.remove(key)
                            : _selectedTrackKeys.add(key));
                      } else {
                        MainTabNavigation.openMap(context);
                      }
                    },
                    onTrackLongPress: (key) {
                      if (!_isTrackSelectionMode) {
                        setState(() {
                          _isTrackSelectionMode = true;
                          _selectedTrackKeys.add(key);
                        });
                      }
                    },
                    onDeleteTrack: (key) => archiveDeleteTrack(
                        context, context.read<TrackService>(), key),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : const AppBottomNavBar(activeRoute: '/archive'),
      floatingActionButton: (isSelecting && selCount > 0)
          ? Padding(
              padding: EdgeInsets.only(
                  bottom: AppBottomNavBar.overlayClearanceAboveNav(context)),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1976D2),
                onPressed: () {
                  if (isStationsTab) {
                    final repo = context.read<StationRepository>();
                    final selectedStations = repo.stations
                        .where(
                            (s) => _selectedStationKeys.contains(s.key as int))
                        .toList();
                    presentArchiveStationsExportSheet(
                      context,
                      stations: selectedStations,
                      projectLabel: _selectedProject ?? 'Archive',
                      onShareFile: _shareExportedFile,
                    );
                  } else {
                    final trackSvc = context.read<TrackService>();
                    final selectedTracks = trackSvc.storedTracks
                        .where((t) => _selectedTrackKeys.contains(t.key as int))
                        .toList();
                    presentArchiveTracksExportSheet(
                      context,
                      tracks: selectedTracks,
                      onShareFile: _shareExportedFile,
                    );
                  }
                },
                label: Text(context.loc('share')),
                icon: const Icon(Icons.share),
              ),
            )
          : null,
    );
  }
}
