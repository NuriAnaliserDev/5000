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
  if (result.importedCount == 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.gis_import_empty_result),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
    return;
  }
  var msg = strings.gis_import_done(result.importedCount, result.skippedCount);
  if (result.normalizedCoordinates) {
    msg = '$msg\n${strings.gis_import_normalized_hint}';
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: result.normalizedCoordinates ? 6 : 4),
    ),
  );
}
