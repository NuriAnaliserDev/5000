import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import '../models/station.dart';
import '../models/track_data.dart';
import 'export/dxf_writer.dart';
import 'export/shapefile_writer.dart';

/// Yagona eksport fasadi: CSV/GeoJSON/KML/GPX/DXF/Shapefile.
///
/// DXF — [DxfWriter] (HEADER + LAYER + UTM).
/// Shapefile — [ShapefileWriter] (WGS84 .prj + ZIP).
/// CSV — UTF-8 BOM (Excel).
/// GPX — metadata (name/time/bounds) + waypoint'lar.
class ExportService {
  static Future<File> exportToCsv(List<Station> stations) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Name,Date,Latitude,Longitude,Altitude,Accuracy,Strike,Dip,Azimuth,RockType,MeasurementType,Structure,Color,Description');

    for (final s in stations) {
      final dateStr = s.date.toIso8601String();
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
        '${_escape(s.description ?? "")}',
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    // UTF-8 BOM — Excel'da kirillcha/o‘zbekcha to‘g‘ri ochilishi uchun.
    return file.writeAsString('\uFEFF${buffer.toString()}');
  }

  static Future<File> exportToGeoJson(List<Station> stations) async {
    final List<Map<String, dynamic>> features = stations
        .map((s) => {
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
              }
            })
        .toList();

    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.geojson');
    return file.writeAsString(jsonEncode(geojson));
  }

  static Future<File> exportToKml(List<Station> stations) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>GeoField Pro Export</name>');

    for (final s in stations) {
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
    final file = File(
        '${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.kml');
    return file.writeAsString(buffer.toString());
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
    final file = File(
        '${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.kml');
    return file.writeAsString(buffer.toString());
  }

  /// GPX 1.1 — `<metadata>` (name, time, bounds) + optional `<wpt>` waypoints.
  static Future<File> exportTracksToGpx(
    List<TrackData> tracks, {
    List<Station> waypoints = const [],
    String name = 'GeoField Pro Tracks',
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="GeoField Pro" xmlns="http://www.topografix.com/GPX/1/1">');

    _writeGpxMetadata(buffer, tracks, waypoints, name);

    for (final s in waypoints) {
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
    final file = File(
        '${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.gpx');
    return file.writeAsString(buffer.toString());
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
    List<TrackData> tracks,
  ) {
    return ShapefileWriter.writeZip(stations: stations, tracks: tracks);
  }

  /// DXF — HEADER+TABLES+ENTITIES, UTM metrlarida.
  static Future<File> exportToDxf(
    List<Station> stations,
    List<TrackData> tracks, {
    bool useUtm = true,
  }) {
    return DxfWriter.write(
      stations: stations,
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
