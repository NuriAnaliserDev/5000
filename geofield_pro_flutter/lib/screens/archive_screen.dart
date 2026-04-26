import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import '../services/station_repository.dart';
import '../services/track_service.dart';
import '../utils/app_nav_bar.dart';
import '../services/settings_controller.dart';
import '../services/export_service.dart';
import '../services/pdf_export_service.dart';
import '../utils/app_localizations.dart';

import 'archive/tabs/stations_tab.dart';
import 'archive/tabs/tracks_tab.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedProject;
  bool _isSelectionMode = false;
  bool _isTrackSelectionMode = false;
  final Set<int> _selectedStationKeys = {};
  final Set<int> _selectedTrackKeys = {};
  late TabController _tabController;

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

  Future<void> _deleteWithUndo(BuildContext context, StationRepository repo, Station s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('delete')),
        content: Text('"${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final key = s.key as int;
    final backup = s.copyWith();
    await repo.deleteStation(key);
    if (!mounted) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.loc('success_saved')),
        action: SnackBarAction(label: context.loc('cancel'), onPressed: () => repo.addStation(backup)),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  Future<void> _deleteTrack(BuildContext context, TrackService trackSvc, int key) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('delete')),
        content: Text(context.loc('confirm_delete')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await trackSvc.deleteTrack(key);
    }
  }

  void _showExportDialog(BuildContext context, List<Station> stations) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.loc('export_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(context.loc('export_pdf')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await PdfExportService.generateProjectReport(stations, _selectedProject ?? 'Archive');
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: Text(context.loc('export_csv')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToCsv(stations);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.orange),
                title: Text(context.loc('export_geojson')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToGeoJson(stations);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: Text(context.loc('export_kml')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToKml(stations);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined, color: Colors.brown),
                title: const Text('Shapefile (ZIP)'),
                subtitle: const Text(
                  'QGIS: stations.shp + WGS84 .prj. Yo‘llar alohida track_*.shp',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToShapefileZip(stations, const []);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.architecture, color: Colors.cyan),
                title: const Text('Export DXF (AutoCAD)'),
                subtitle: const Text(
                  'UTM metr (zona) — AutoCAD o‘lchovi bilan ochiladi',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToDxf(stations, []);
                  _shareFile(file);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareFile(File file) async {
    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'GeoField Pro N Export');
    setState(() {
      _isSelectionMode = false;
      _isTrackSelectionMode = false;
      _selectedStationKeys.clear();
      _selectedTrackKeys.clear();
    });
  }

  void _showTracksExportDialog(BuildContext context, List<TrackData> tracks) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.loc('export_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: Text(context.loc('export_kml')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportTracksToKml(tracks);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.route, color: Colors.orange),
                title: const Text('GPX (GPS Exchange Format)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportTracksToGpx(tracks);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined, color: Colors.brown),
                title: const Text('Shapefile (ZIP)'),
                subtitle: const Text(
                  'Har track — alohida polyline .shp, WGS84 .prj',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToShapefileZip(const [], tracks);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.architecture, color: Colors.cyan),
                title: const Text('Export DXF (AutoCAD)'),
                subtitle: const Text(
                  'UTM metr (zona) — poliline va nuqtalar',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ExportService.exportToDxf([], tracks);
                  _shareFile(file);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedStations() async {
    final repo = context.read<StationRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('delete')),
        content: Text('${_selectedStationKeys.length} ${context.loc('selected_label')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      final keys = _selectedStationKeys.toList();
      for (final k in keys) {
        await repo.deleteStation(k);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedStationKeys.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc('success_saved'))));
    }
  }

  Future<void> _deleteSelectedTracks() async {
    final trackSvc = context.read<TrackService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('delete')),
        content: Text('${_selectedTrackKeys.length} ${context.loc('selected_label')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      final keys = _selectedTrackKeys.toList();
      for (final k in keys) {
        await trackSvc.deleteTrack(k);
      }
      setState(() {
        _isTrackSelectionMode = false;
        _selectedTrackKeys.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc('success_saved'))));
    }
  }

  void _showFilterDialog() {
    final settings = context.read<SettingsController>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.loc('filter'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: context.loc('by_project'),
                  border: const OutlineInputBorder(),
                ),
                initialValue: _selectedProject,
                items: [
                  DropdownMenuItem(value: null, child: Text(context.loc('all_projects'))),
                  ...settings.projects.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                ],
                onChanged: (val) {
                  setState(() => _selectedProject = val);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    final bool isStationsTab = _tabController.index == 0;
    final bool isSelecting = isStationsTab ? _isSelectionMode : _isTrackSelectionMode;
    final int selCount = isStationsTab ? _selectedStationKeys.length : _selectedTrackKeys.length;

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
        actions: isSelecting ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: context.loc('delete'),
            onPressed: isStationsTab ? _deleteSelectedStations : _deleteSelectedTracks,
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
        ] : [
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedProject != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_selectedProject!, style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _selectedProject = null),
                      avatar: const Icon(Icons.close, size: 14),
                      backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: TabBarView(
                controller: _tabController,
                children: [
                  ArchiveStationsTab(
                    searchQuery: _searchQuery,
                    selectedProject: _selectedProject,
                    isSelectionMode: _isSelectionMode,
                    selectedStationKeys: _selectedStationKeys,
                    onSelectionChanged: (key, val) => setState(() => val ? _selectedStationKeys.add(key) : _selectedStationKeys.remove(key)),
                    onStationTap: (key) {
                      if (_isSelectionMode) {
                        setState(() => _selectedStationKeys.contains(key) ? _selectedStationKeys.remove(key) : _selectedStationKeys.add(key));
                      } else {
                        Navigator.of(context).pushNamed('/station', arguments: key);
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
                    onDeleteStation: (s) => _deleteWithUndo(context, context.read<StationRepository>(), s),
                  ),
                  ArchiveTracksTab(
                    searchQuery: _searchQuery,
                    isSelectionMode: _isTrackSelectionMode,
                    selectedTrackKeys: _selectedTrackKeys,
                    onSelectionChanged: (key, val) => setState(() => val ? _selectedTrackKeys.add(key) : _selectedTrackKeys.remove(key)),
                    onTrackTap: (key) {
                      if (_isTrackSelectionMode) {
                        setState(() => _selectedTrackKeys.contains(key) ? _selectedTrackKeys.remove(key) : _selectedTrackKeys.add(key));
                      } else {
                        Navigator.of(context).pushNamed('/map');
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
                    onDeleteTrack: (key) => _deleteTrack(context, context.read<TrackService>(), key),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/archive'),
      floatingActionButton: (isSelecting && selCount > 0)
        ? Padding(
          padding: const EdgeInsets.only(bottom: 72),
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1976D2),
            onPressed: () {
              if (isStationsTab) {
                final repo = context.read<StationRepository>();
                final selectedStations = repo.stations.where((s) => _selectedStationKeys.contains(s.key as int)).toList();
                _showExportDialog(context, selectedStations);
              } else {
                final trackSvc = context.read<TrackService>();
                final selectedTracks = trackSvc.storedTracks.where((t) => _selectedTrackKeys.contains(t.key as int)).toList();
                _showTracksExportDialog(context, selectedTracks);
              }
            },
            label: Text(context.loc('share')),
            icon: const Icon(Icons.share),
          ),
        ) : null,
    );
  }
}
