import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/boundary_service.dart';

/// GIS import natijasini foydalanuvchiga aniq xabar qiladi.
void showGisImportResultSnackbar(
  BuildContext context,
  GeoFieldStrings strings,
  BoundaryImportResult result,
) {
  final messenger = ScaffoldMessenger.of(context);
  final inv = result.skippedInvalidCoordinates;
  final few = result.skippedTooFewPoints;
  final skipped = result.skippedCount;

  if (result.importedCount == 0 && skipped == 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.gis_import_empty_result),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
    return;
  }

  if (result.importedCount == 0 && skipped > 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.gis_import_all_skipped_result(inv, few)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.orange.shade800,
      ),
    );
    return;
  }

  var msg = strings.gis_import_done(result.importedCount, skipped);
  if (skipped > 0) {
    msg = '$msg\n${strings.gis_import_skipped_stats(inv, few)}';
  }
  if (result.normalizedCoordinates) {
    msg = '$msg\n${strings.gis_import_normalized_hint}';
  }
  final extendDuration =
      result.normalizedCoordinates || skipped > 0;
  messenger.showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: extendDuration ? 8 : 4),
    ),
  );
}
