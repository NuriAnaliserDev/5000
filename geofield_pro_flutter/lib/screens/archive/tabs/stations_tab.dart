import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/station.dart';
import '../../../services/station_repository.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/app_localizations.dart';

class ArchiveStationsTab extends StatelessWidget {
  final String searchQuery;
  final String? selectedProject;
  final bool isSelectionMode;
  final Set<int> selectedStationKeys;
  final Function(int, bool) onSelectionChanged;
  final Function(int) onStationTap;
  final Function(int) onStationLongPress;
  final Function(Station) onDeleteStation;

  const ArchiveStationsTab({
    super.key,
    required this.searchQuery,
    this.selectedProject,
    required this.isSelectionMode,
    required this.selectedStationKeys,
    required this.onSelectionChanged,
    required this.onStationTap,
    required this.onStationLongPress,
    required this.onDeleteStation,
  });

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final repo = context.watch<StationRepository>();
    var stations = repo.stations;

    if (searchQuery.isNotEmpty) {
      stations = stations.where((s) => s.name.toLowerCase().contains(searchQuery) || (s.description?.toLowerCase().contains(searchQuery) ?? false)).toList();
    }
    if (selectedProject != null) {
      stations = stations.where((s) => s.project == selectedProject).toList();
    }

    if (stations.isEmpty) {
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
                '${stations.length} ${context.loc('results_count')}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              if (!isSelectionMode)
                TextButton.icon(
                  onPressed: () async {
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
                      final keys = stations.map((s) => s.key as int).toList();
                      for (final k in keys) {
                        await repo.deleteStation(k);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.loc('success_saved'))),
                      );
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
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final Station s = stations[index];
              final key = s.key as int;
              final isSelected = selectedStationKeys.contains(key);
              return ListTile(
                leading: isSelectionMode 
                  ? Checkbox(
                      value: isSelected, 
                      onChanged: (v) => onSelectionChanged(key, v ?? false),
                      activeColor: const Color(0xFF1976D2),
                    )
                  : const Icon(Icons.storage, color: Color(0xFF1976D2)),
                title: Text(s.name, style: TextStyle(color: onSurf)),
                subtitle: Text(
                  '${GeologyUtils.toUTM(s.lat, s.lng)}\n${s.date.toLocal().toString().split('.')[0]}', 
                  style: TextStyle(fontSize: 11, color: onSurf.withValues(alpha: 0.7)),
                ),
                trailing: isSelectionMode ? null : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => onDeleteStation(s),
                    ),
                    Icon(Icons.chevron_right, color: onSurf.withValues(alpha: 0.6)),
                  ],
                ),
                selected: isSelected,
                selectedTileColor: const Color(0xFF1976D2).withValues(alpha: 0.05),
                onTap: () => onStationTap(key),
                onLongPress: () => onStationLongPress(key),
              );
            },
          ),
        ),
      ],
    );
  }
}
