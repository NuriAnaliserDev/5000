import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/station.dart';
import '../../models/track_data.dart';
import '../../services/export_service.dart';
import '../../services/pdf_export_service.dart';
import '../../utils/app_localizations.dart';

Future<void> presentArchiveStationsExportSheet(
  BuildContext context, {
  required List<Station> stations,
  required String projectLabel,
  required Future<void> Function(File file) onShareFile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.loc('export_title'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(ctx.loc('export_pdf')),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await PdfExportService.generateProjectReport(
                    stations, projectLabel);
                await onShareFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(ctx.loc('export_csv')),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportService.exportToCsv(stations);
                await onShareFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.orange),
              title: Text(ctx.loc('export_geojson')),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportService.exportToGeoJson(stations);
                await onShareFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: Text(ctx.loc('export_kml')),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportService.exportToKml(stations);
                await onShareFile(file);
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
                final file = await ExportService.exportToShapefileZip(
                    stations, const []);
                await onShareFile(file);
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
                await onShareFile(file);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

Future<void> presentArchiveTracksExportSheet(
  BuildContext context, {
  required List<TrackData> tracks,
  required Future<void> Function(File file) onShareFile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.loc('export_title'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: Text(ctx.loc('export_kml')),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportService.exportTracksToKml(tracks);
                await onShareFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.orange),
              title: const Text('GPX (GPS Exchange Format)'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ExportService.exportTracksToGpx(tracks);
                await onShareFile(file);
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
                final file =
                    await ExportService.exportToShapefileZip(const [], tracks);
                await onShareFile(file);
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
                await onShareFile(file);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
