import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/track_data.dart';
import '../../../services/track_service.dart';
import '../../../utils/app_localizations.dart';

class ArchiveTracksTab extends StatelessWidget {
  final String searchQuery;
  final bool isSelectionMode;
  final Set<int> selectedTrackKeys;
  final Function(int, bool) onSelectionChanged;
  final Function(int) onTrackTap;
  final Function(int) onTrackLongPress;
  final Function(int) onDeleteTrack;

  const ArchiveTracksTab({
    super.key,
    required this.searchQuery,
    required this.isSelectionMode,
    required this.selectedTrackKeys,
    required this.onSelectionChanged,
    required this.onTrackTap,
    required this.onTrackLongPress,
    required this.onDeleteTrack,
  });

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final trackSvc = context.watch<TrackService>();
    var tracks = trackSvc.storedTracks;

    if (searchQuery.isNotEmpty) {
      tracks = tracks.where((t) => t.name.toLowerCase().contains(searchQuery)).toList();
    }

    if (tracks.isEmpty) {
      return Center(child: Text(context.loc('no_data'), style: TextStyle(color: onSurf.withValues(alpha: 0.7))));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tracks.length} ${context.loc('results_count')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              if (!isSelectionMode)
                TextButton.icon(
                  onPressed: () async {
                    if (tracks.isEmpty) return;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.loc('delete_all_label')),
                        content: Text(context.locRead('confirm_delete_all_tracks')),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      for (final t in tracks) {
                        await trackSvc.deleteTrack(t.key as int);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc('success_saved'))));
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                  label: Text(context.loc('delete'), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final t = tracks[index];
              final key = t.key as int;
              final isSelected = selectedTrackKeys.contains(key);
              return ListTile(
                leading: isSelectionMode 
                  ? Checkbox(
                      value: isSelected, 
                      onChanged: (v) => onSelectionChanged(key, v ?? false),
                      activeColor: const Color(0xFF1976D2),
                    )
                  : const Icon(Icons.route, color: Colors.blue),
                title: Text(t.name, style: TextStyle(color: onSurf)),
                subtitle: Text(
                  '${context.loc('distance_label')}: ${(t.distanceMeters / 1000).toStringAsFixed(2)} km  •  ${context.loc('stations')}: ${t.points.length}',
                  style: TextStyle(color: onSurf.withValues(alpha: 0.7)),
                ),
                trailing: isSelectionMode ? null : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      tooltip: context.loc('rename_route'),
                      onPressed: () => _renameTrack(context, trackSvc, t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      tooltip: 'GPX Eksport',
                      onPressed: () => _exportTrackGpx(context, t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => onDeleteTrack(key),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedTileColor: const Color(0xFF1976D2).withValues(alpha: 0.05),
                onTap: () => onTrackTap(key),
                onLongPress: () => onTrackLongPress(key),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _renameTrack(BuildContext context, TrackService trackSvc, TrackData t) async {
    final ctrl = TextEditingController(text: t.name);
    final newName = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('rename_route')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Yangi nom'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(context.loc('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text(context.loc('save')),
          ),
        ],
      ),
    );
    if (newName != null && newName.trim().isNotEmpty) {
      await trackSvc.renameTrack(t.key as int, newName.trim());
    }
  }

  Future<void> _exportTrackGpx(BuildContext context, TrackData t) async {
    try {
      final StringBuffer gpx = StringBuffer();
      gpx.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      gpx.writeln('<gpx version="1.1" creator="GeoField Pro N" xmlns="http://www.topografix.com/GPX/1/1">');
      gpx.writeln('  <metadata><name>${t.name}</name></metadata>');
      gpx.writeln('  <trk>');
      gpx.writeln('    <name>${t.name}</name>');
      gpx.writeln('    <trkseg>');
      for (var p in t.points) {
        gpx.writeln('      <trkpt lat="${p.lat}" lon="${p.lng}">');
        gpx.writeln('        <ele>${p.alt}</ele>');
        gpx.writeln('        <time>${p.time.toUtc().toIso8601String()}</time>');
        gpx.writeln('      </trkpt>');
      }
      gpx.writeln('    </trkseg>');
      gpx.writeln('  </trk>');
      gpx.writeln('</gpx>');

      final dir = await getTemporaryDirectory();
      final safeName = t.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final file = File('${dir.path}/$safeName.gpx');
      await file.writeAsString(gpx.toString());
      
      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'GeoField Pro N: ${t.name}');
    } catch (e) {
      debugPrint('GPX Export xatosi: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik yuz berdi: $e')));
      }
    }
  }
}
