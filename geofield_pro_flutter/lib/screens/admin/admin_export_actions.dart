import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/export_service.dart';
import '../../services/station_excel_export.dart';
import '../../services/station_repository.dart';
import '../../utils/app_localizations.dart';

Future<void> adminConfirmClearAllStations(BuildContext context) async {
  final repo = context.read<StationRepository>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.locRead('warning_label')),
      content: Text(
        context.locRead('confirm_delete_all'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.locRead('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(context.locRead('delete_confirm_btn')),
        ),
      ],
    ),
  );

  if (ok == true) {
    await repo.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('success_saved'))),
      );
    }
  }
}

Future<void> adminExportStations(
  BuildContext context,
  StationRepository repo, {
  bool isCsv = false,
  bool isExcel = false,
}) async {
  if (repo.stations.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.locRead('export_no_stations'))),
    );
    return;
  }

  final projects = repo.stations
      .map((s) => s.project)
      .where((p) => p != null)
      .map((e) => e as String)
      .toSet()
      .toList();
  if (!projects.contains(context.loc('all_stations'))) {
    projects.insert(0, context.loc('all_stations'));
  }
  if (!projects.contains(context.loc('today_only'))) {
    projects.insert(1, context.loc('today_only'));
  }

  final selectedProject = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.locRead('export_select_project')),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(projects[i]),
                onTap: () => Navigator.of(ctx).pop(projects[i]),
              ),
            ),
          ),
        );
      });

  if (selectedProject == null) return;
  if (!context.mounted) return;

  final toExport = selectedProject == context.locRead('all_stations')
      ? repo.stations
      : selectedProject == context.locRead('today_only')
          ? repo.stations.where((s) {
              final now = DateTime.now();
              return s.date.year == now.year &&
                  s.date.month == now.month &&
                  s.date.day == now.day;
            }).toList()
          : repo.stations.where((s) => s.project == selectedProject).toList();

  if (toExport.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.locRead('no_stations_in_project'))),
    );
    return;
  }

  final file = isExcel
      ? await StationExcelExport.writeStationsFile(toExport)
      : isCsv
          ? await ExportService.exportToCsv(toExport)
          : await ExportService.exportToGeoJson(toExport);

  if (!context.mounted) return;
  await Share.shareXFiles([XFile(file.path)],
      text: 'GeoField Pro N: $selectedProject export');
}
