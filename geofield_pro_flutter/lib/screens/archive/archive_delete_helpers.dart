import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/station.dart';
import '../../services/station_repository.dart';
import '../../services/track_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/app_nav_bar.dart';

Future<void> archiveDeleteStationWithUndo(
  BuildContext context,
  StationRepository repo,
  Station s,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.loc('delete')),
      content: Text('"${s.name}"?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.loc('cancel'))),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.loc('delete'),
                style: const TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final key = s.key as int;
  final backup = s.copyWith();
  await repo.deleteStation(key);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        GeoFieldStrings.of(context)!.station_deleted_snack(s.name),
      ),
      action: SnackBarAction(
        label: GeoFieldStrings.of(context)!.snackbar_undo_restore,
        onPressed: () => repo.addStation(backup),
      ),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: AppBottomNavBar.overlayClearanceAboveNav(context),
        left: 16,
        right: 16,
      ),
    ),
  );
}

Future<void> archiveDeleteTrack(
    BuildContext context, TrackService trackSvc, int key) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.loc('delete')),
      content: Text(ctx.loc('confirm_delete')),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.loc('cancel'))),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.loc('delete'),
                style: const TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (ok == true) {
    await trackSvc.deleteTrack(key);
  }
}

Future<void> archiveDeleteSelectedStations(
  BuildContext context, {
  required Set<int> selectedKeys,
  required VoidCallback onCleared,
}) async {
  final repo = context.read<StationRepository>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.loc('delete')),
      content: Text(
          '${selectedKeys.length} ${ctx.loc('selected_label')}?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.loc('cancel'))),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.loc('delete'),
                style: const TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (ok == true) {
    final keys = selectedKeys.toList();
    for (final k in keys) {
      await repo.deleteStation(k);
    }
    onCleared();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.loc('success_saved'))));
    }
  }
}

Future<void> archiveDeleteSelectedTracks(
  BuildContext context, {
  required Set<int> selectedKeys,
  required VoidCallback onCleared,
}) async {
  final trackSvc = context.read<TrackService>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.loc('delete')),
      content: Text(
          '${selectedKeys.length} ${ctx.loc('selected_label')}?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.loc('cancel'))),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.loc('delete'),
                style: const TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (ok == true) {
    final keys = selectedKeys.toList();
    for (final k in keys) {
      await trackSvc.deleteTrack(k);
    }
    onCleared();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.loc('success_saved'))));
    }
  }
}
