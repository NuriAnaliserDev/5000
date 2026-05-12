import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/error/error_mapper.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/boundary_service.dart';
import '../../../services/elevation_service.dart';
import '../../../services/geological_line_repository.dart';
import '../../../utils/gis_geojson_export.dart';
import '../../../utils/utm_wgs84.dart';

class MapCenterActions {
  const MapCenterActions._();

  static void copyUtmCenterToClipboard(BuildContext context, LatLng center) {
    final text = UtmWgs84.formatUtm(center);
    Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> showCenterElevation(
    BuildContext context,
    LatLng center,
  ) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.elevation_lookup_progress),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final meters = await ElevationService.fetchElevationMeters(center);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          meters == null
              ? s.elevation_lookup_failed
              : s.elevation_meters_result(meters.toStringAsFixed(1)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> exportGeoJson(BuildContext context) async {
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    try {
      final lines = context.read<GeologicalLineRepository>().getAllLines();
      final boundaries = context.read<BoundaryService>().boundaries;
      final text = GisGeoJsonExport.buildString(
        lines: lines,
        boundaries: boundaries,
      );
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.map_export_geojson),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.geojson',
      );
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: s.map_export_geojson);
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
  }
}
