import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/error/error_mapper.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/boundary_service.dart';
import '../../../services/location_service.dart';
import '../../../utils/gis_import_feedback.dart';
import '../../../widgets/gis_import_precheck_dialog.dart';

class MapGisImportAction {
  const MapGisImportAction._();

  static Future<List<LatLng>?> importFromMap(
    BuildContext context, {
    required LatLng fallbackCenter,
  }) async {
    final boundary = context.read<BoundaryService>();
    final s = GeoFieldStrings.of(context);
    try {
      final ok = await showGisImportPrecheckDialog(context);
      if (!ok || !context.mounted) {
        return null;
      }
      final pos = context.read<LocationService>().currentPosition;
      final result = await boundary.importFileFromWeb(
        hintLatitude: pos?.latitude ?? fallbackCenter.latitude,
        hintLongitude: pos?.longitude ?? fallbackCenter.longitude,
      );
      if (!context.mounted || result == null) {
        return null;
      }
      if (s != null) {
        showGisImportResultSnackbar(context, s, result);
      }
      return result.fitPoints;
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
      return null;
    }
  }
}
