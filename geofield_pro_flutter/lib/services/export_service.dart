import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:path_provider/path_provider.dart';

import '../core/diagnostics/production_diagnostics.dart';
import '../models/field_trust_category.dart';
import '../models/field_trust_meta.dart';
import '../services/observation_pipeline_service.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import 'export/dxf_writer.dart';
import 'export/shapefile_writer.dart';

/// `strict`: validatsiya xatosi bo‘lsa eksport qilmaydi. `soft`: fayl + log.
enum ExportIntegrityMode {
  soft,
  strict,
}

/// Yagona eksport fasadi: CSV/GeoJSON/KML/GPX/DXF/Shapefile.
///
/// DXF — [DxfWriter] (HEADER + LAYER + UTM).
/// Shapefile — [ShapefileWriter] (WGS84 .prj + ZIP).
/// CSV — UTF-8 BOM (Excel).
/// GPX — metadata (name/time/bounds) + waypoint'lar.
class ExportService {
  /// Tartib: avval `date` kamayish, keyin `name`.
  static List<Station> orderedForExport(List<Station> stations) {
    final out = List<Station>.from(stations);
    out.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  static void logExportSummary(
    String format,
    List<Station> ordered,
    List<String> issues,
    ExportIntegrityMode mode,
  ) {
    if (issues.isEmpty) return;
    unawaited(
      ProductionDiagnostics.storage(
        'export_completed_summary',
        phase: format,
        data: {
          'mode': mode.name,
          'rows': ordered.length,
          'issues': issues.length,
          'strict_blocked':
              mode == ExportIntegrityMode.strict && issues.isNotEmpty,
        },
      ),
    );
  }

  /// Eksportdan oldin: takrorlar, vaqt, fayl yo‘qligi — soft rejimda fayl baribir yoziladi.
  static List<String> validateStationsForExport(List<Station> stations) {
    final issues = <String>[];
    final keys = <String>{};
    for (var i = 0; i < stations.length; i++) {
      final s = stations[i];
      final d = s.date;
      if (d.year < 1980 || d.year > 2100) {
        issues.add('export_date_range:$i:${s.name}');
      }
      if (d.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        issues.add('export_time_future:$i:${s.name}');
      }
      final key = '${s.name}|${d.toIso8601String()}';
      if (keys.contains(key)) {
        issues.add('export_dup_name_date:${s.name}');
      }
      keys.add(key);
      final meta = ObservationPipelineService.canonicalFieldTrustMeta(s);
      if (meta != null) {
        if (meta.category == FieldTrustCategory.invalid) {
          issues.add('export_category_invalid:${s.name}');
        }
        if (meta.category == FieldTrustCategory.mocked) {
          issues.add('export_category_mocked:${s.name}');
        }
      }
      if (meta != null && meta.trustScore < 35) {
        issues.add('export_diagnostic_low_score:${s.name}:${meta.trustScore}');
      }
      if (s.lat == 0 && s.lng == 0) {
        final t = ObservationPipelineService.canonicalFieldTrustMeta(s);
        if (t?.allowsNullIslandCoordinates != true) {
          issues.add('export_null_coords_untagged:${s.name}');
        }
      }
      try {
        final paths = <String>{};
        if (s.photoPath != null && s.photoPath!.isNotEmpty) {
          paths.add(s.photoPath!);
        }
        if (s.photoPaths != null) {
          for (final p in s.photoPaths!) {
            if (p.isNotEmpty) paths.add(p);
          }
        }
        for (final p in paths) {
          final f = File(p);
          if (!f.existsSync()) {
            issues.add('export_missing_photo:$i:${s.name}');
          } else if (f.lengthSync() < 32) {
            issues.add('export_tiny_photo:$i:${s.name}');
          }
        }
      } catch (_) {}
    }
    return issues;
  }

  static void logExportValidation(
    String format,
    List<Station> stations,
    List<String> issues,
  ) {
    if (issues.isEmpty) return;
    unawaited(
      ProductionDiagnostics.storage(
        'export_validation_issues',
        phase: format,
        data: {
          'station_count': stations.length,
          'issue_count': issues.length,
          'sample': issues.take(12).join('|'),
        },
      ),
    );
  }

  /// Yozish vaqtida ilova o‘chsa ham bo‘sh/buzuq fayl qolmasligi uchun vaqtinchalik fayl orqali almashtirish.
  static Future<File> _atomicWriteUtf8Text(String path, String contents) async {
    final target = File(path);
    final tmp = File('$path.tmp.${DateTime.now().microsecondsSinceEpoch}');
    await tmp.writeAsString(contents, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(target.path);
    return target;
  }

  static Future<File> exportToCsv(
    List<Station> stations, {
    ExportIntegrityMode integrityMode = ExportIntegrityMode.soft,
  }) async {
    final ordered = orderedForExport(stations);
    final issues = validateStationsForExport(ordered);
    logExportValidation('csv', ordered, issues);
    logExportSummary('csv', ordered, issues, integrityMode);
    if (integrityMode == ExportIntegrityMode.strict && issues.isNotEmpty) {
      throw StateError('export_validation_failed:${issues.take(8).join(',')}');
    }
    final buffer = StringBuffer();
    buffer.writeln(
        'Name,Date,Latitude,Longitude,Altitude,Accuracy,Strike,Dip,Azimuth,RockType,MeasurementType,Structure,Color,Description,TrustCategory,TrustScore,ImageSha256,TrustMetaJson');

    for (final s in ordered) {
      final dateStr = s.date.toIso8601String();
      final meta = FieldTrustMeta.decode(s.fieldTrustMetaJson);
      buffer.writeln(
        '${_escape(s.name)},'
        '$dateStr,'
        '${s.lat},'
        '${s.lng},'
        '${s.altitude},'
        '${s.accuracy ?? ""},'
        '${s.strike},'
        '${s.dip},'
        '${s.azimuth},'
        '${_escape(s.rockType ?? "")},'
        '${_escape(s.measurementType ?? "")},'
        '${_escape(s.structure ?? "")},'
        '${_escape(s.color ?? "")},'
        '${_escape(s.description ?? "")},'
        '${meta?.category.name.toUpperCase() ?? ""},'
        '${meta?.trustScore ?? ""},'
        '${meta?.imageSha256 ?? ""},'
        '${_escape(s.fieldTrustMetaJson ?? "")}',
      );
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    return _atomicWriteUtf8Text(path, '\uFEFF${buffer.toString()}');
  }

  static Future<File> exportToGeoJson(
    List<Station> stations, {
    ExportIntegrityMode integrityMode = ExportIntegrityMode.soft,
  }) async {
    final ordered = orderedForExport(stations);
    final issues = validateStationsForExport(ordered);
    logExportValidation('geojson', ordered, issues);
    logExportSummary('geojson', ordered, issues, integrityMode);
    if (integrityMode == ExportIntegrityMode.strict && issues.isNotEmpty) {
      throw StateError('export_validation_failed:${issues.take(8).join(',')}');
    }
    final List<Map<String, dynamic>> features = ordered.map((s) {
      final m = FieldTrustMeta.decode(s.fieldTrustMetaJson);
      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [s.lng, s.lat, s.altitude],
        },
        'properties': {
          'name': s.name,
          'date': s.date.toIso8601String(),
          'strike': s.strike,
          'dip': s.dip,
          'azimuth': s.azimuth,
          'accuracy': s.accuracy,
          'rockType': s.rockType,
          'measurementType': s.measurementType,
          'structure': s.structure,
          'color': s.color,
          'description': s.description,
          'project': s.project,
          'trustCategory': m?.category.name.toUpperCase(),
          'trustScore': m?.trustScore,
          'imageSha256': m?.imageSha256,
          'trustMetaJson': s.fieldTrustMetaJson,
        },
      };
    }).toList();

    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.geojson';
    return _atomicWriteUtf8Text(path, jsonEncode(geojson));
  }

  static Future<File> exportToKml(
    List<Station> stations, {
    ExportIntegrityMode integrityMode = ExportIntegrityMode.soft,
  }) async {
    final ordered = orderedForExport(stations);
    final issues = validateStationsForExport(ordered);
    logExportValidation('kml', ordered, issues);
    logExportSummary('kml', ordered, issues, integrityMode);
    if (integrityMode == ExportIntegrityMode.strict && issues.isNotEmpty) {
      throw StateError('export_validation_failed:${issues.take(8).join(',')}');
    }
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>GeoField Pro Export</name>');

    for (final s in ordered) {
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${_escapeXml(s.name)}</name>');
      buffer.writeln(
          '      <description>${_escapeXml(s.description ?? "")}</description>');
      buffer.writeln('      <Point>');
      buffer.writeln(
          '        <coordinates>${s.lng},${s.lat},${s.altitude}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.kml';
    return _atomicWriteUtf8Text(path, buffer.toString());
  }

  static Future<File> exportTracksToKml(List<TrackData> tracks) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>GeoField Pro Tracks</name>');

    for (final t in tracks) {
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${_escapeXml(t.name)}</name>');
      buffer.writeln('      <LineString>');
      buffer.writeln('        <extrude>1</extrude>');
      buffer.writeln('        <tessellate>1</tessellate>');
      buffer.writeln('        <altitudeMode>relativeToGround</altitudeMode>');
      buffer.writeln('        <coordinates>');
      for (final p in t.points) {
        buffer.write('${p.lng},${p.lat},${p.alt} ');
      }
      buffer.writeln('\n        </coordinates>');
      buffer.writeln('      </LineString>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.kml';
    return _atomicWriteUtf8Text(path, buffer.toString());
  }

  /// GPX 1.1 — `<metadata>` (name, time, bounds) + optional `<wpt>` waypoints.
  static Future<File> exportTracksToGpx(
    List<TrackData> tracks, {
    List<Station> waypoints = const [],
    String name = 'GeoField Pro Tracks',
    ExportIntegrityMode waypointIntegrityMode = ExportIntegrityMode.soft,
  }) async {
    final orderedWp = orderedForExport(waypoints);
    final wIssues = validateStationsForExport(orderedWp);
    logExportValidation('gpx_waypoints', orderedWp, wIssues);
    logExportSummary('gpx', orderedWp, wIssues, waypointIntegrityMode);
    if (waypointIntegrityMode == ExportIntegrityMode.strict &&
        wIssues.isNotEmpty) {
      throw StateError('export_validation_failed:${wIssues.take(8).join(',')}');
    }
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="GeoField Pro" xmlns="http://www.topografix.com/GPX/1/1">');

    _writeGpxMetadata(buffer, tracks, orderedWp, name);

    for (final s in orderedWp) {
      buffer.writeln('  <wpt lat="${s.lat}" lon="${s.lng}">');
      buffer.writeln('    <ele>${s.altitude}</ele>');
      buffer.writeln('    <time>${s.date.toUtc().toIso8601String()}</time>');
      buffer.writeln('    <name>${_escapeXml(s.name)}</name>');
      if (s.description != null && s.description!.isNotEmpty) {
        buffer.writeln('    <desc>${_escapeXml(s.description!)}</desc>');
      }
      buffer.writeln('  </wpt>');
    }

    for (final t in tracks) {
      buffer.writeln('  <trk>');
      buffer.writeln('    <name>${_escapeXml(t.name)}</name>');
      buffer.writeln('    <trkseg>');
      for (final p in t.points) {
        final timeStr = p.time.toUtc().toIso8601String();
        buffer.writeln('      <trkpt lat="${p.lat}" lon="${p.lng}">');
        buffer.writeln('        <ele>${p.alt}</ele>');
        buffer.writeln('        <time>$timeStr</time>');
        buffer.writeln('      </trkpt>');
      }
      buffer.writeln('    </trkseg>');
      buffer.writeln('  </trk>');
    }

    buffer.writeln('</gpx>');

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.gpx';
    return _atomicWriteUtf8Text(path, buffer.toString());
  }

  static void _writeGpxMetadata(
    StringBuffer b,
    List<TrackData> tracks,
    List<Station> waypoints,
    String name,
  ) {
    double? minLat, maxLat, minLng, maxLng;

    void extend(double lat, double lng) {
      minLat = minLat == null ? lat : (lat < minLat! ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat! ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng! ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng! ? lng : maxLng);
    }

    for (final t in tracks) {
      for (final p in t.points) {
        extend(p.lat, p.lng);
      }
    }
    for (final s in waypoints) {
      extend(s.lat, s.lng);
    }

    b.writeln('  <metadata>');
    b.writeln('    <name>${_escapeXml(name)}</name>');
    b.writeln('    <time>${DateTime.now().toUtc().toIso8601String()}</time>');
    if (minLat != null) {
      b.writeln(
          '    <bounds minlat="$minLat" minlon="$minLng" maxlat="$maxLat" maxlon="$maxLng"/>');
    }
    b.writeln('  </metadata>');
  }

  /// Shapefile ZIP — `stations.*` + har track uchun `track_N_*.shp`.
  static Future<File> exportToShapefileZip(
    List<Station> stations,
    List<TrackData> tracks, {
    ExportIntegrityMode integrityMode = ExportIntegrityMode.soft,
  }) {
    final ordered = orderedForExport(stations);
    final issues = validateStationsForExport(ordered);
    logExportValidation('shapefile_zip', ordered, issues);
    logExportSummary('shapefile_zip', ordered, issues, integrityMode);
    if (integrityMode == ExportIntegrityMode.strict && issues.isNotEmpty) {
      throw StateError('export_validation_failed:${issues.take(8).join(',')}');
    }
    return ShapefileWriter.writeZip(stations: ordered, tracks: tracks);
  }

  /// DXF — HEADER+TABLES+ENTITIES, UTM metrlarida.
  static Future<File> exportToDxf(
    List<Station> stations,
    List<TrackData> tracks, {
    bool useUtm = true,
    ExportIntegrityMode integrityMode = ExportIntegrityMode.soft,
  }) {
    final ordered = orderedForExport(stations);
    final issues = validateStationsForExport(ordered);
    logExportValidation('dxf', ordered, issues);
    logExportSummary('dxf', ordered, issues, integrityMode);
    if (integrityMode == ExportIntegrityMode.strict && issues.isNotEmpty) {
      throw StateError('export_validation_failed:${issues.take(8).join(',')}');
    }
    return DxfWriter.write(
      stations: ordered,
      tracks: tracks,
      useUtm: useUtm,
    );
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _escape(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
