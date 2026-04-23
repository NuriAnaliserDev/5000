import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/station.dart';
import '../models/track_data.dart';

class ExportService {
  static Future<File> exportToCsv(List<Station> stations) async {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('Name,Date,Latitude,Longitude,Altitude,Accuracy,Strike,Dip,Azimuth,RockType,MeasurementType,Structure,Color,Description');

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
        '${_escape(s.description ?? "")}'
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    return await file.writeAsString(buffer.toString());
  }

  static Future<File> exportToGeoJson(List<Station> stations) async {
    final List<Map<String, dynamic>> features = stations.map((s) => {
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
    }).toList();

    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.geojson');
    return await file.writeAsString(jsonEncode(geojson));
  }

  static Future<File> exportToKml(List<Station> stations) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>GeoField Pro N Export</name>');

    for (final s in stations) {
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${_escapeXml(s.name)}</name>');
      buffer.writeln('      <description>${_escapeXml(s.description ?? "")}</description>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${s.lng},${s.lat},${s.altitude}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.kml');
    return await file.writeAsString(buffer.toString());
  }

  static Future<File> exportTracksToKml(List<TrackData> tracks) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>GeoField Pro N Tracks</name>');

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
    final file = File('${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.kml');
    return await file.writeAsString(buffer.toString());
  }

  static Future<File> exportTracksToGpx(List<TrackData> tracks) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="GeoField Pro N" xmlns="http://www.topografix.com/GPX/1/1">');

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
    final file = File('${directory.path}/tracks_export_${DateTime.now().millisecondsSinceEpoch}.gpx');
    return await file.writeAsString(buffer.toString());
  }

  static Future<File> exportToDxf(List<Station> stations, List<TrackData> tracks) async {
    final buffer = StringBuffer();
    // DXF Header
    buffer.writeln('  0\nSECTION\n  2\nENTITIES');
    
    // Stations as POINT entities
    for (final s in stations) {
      buffer.writeln('  0\nPOINT\n  8\nStations');
      buffer.writeln(' 10\n${s.lng}\n 20\n${s.lat}\n 30\n${s.altitude}');
    }

    // Tracks as LWPOLYLINE entities
    for (final t in tracks) {
      if (t.points.isEmpty) continue;
      buffer.writeln('  0\nLWPOLYLINE\n  8\nTracks');
      buffer.writeln(' 90\n${t.points.length}\n 70\n0'); // 70=0 means open polyline
      for (final p in t.points) {
        buffer.writeln(' 10\n${p.lng}\n 20\n${p.lat}');
      }
    }
    
    // EOF
    buffer.writeln('  0\nENDSEC\n  0\nEOF');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/geofield_export_${DateTime.now().millisecondsSinceEpoch}.dxf');
    return await file.writeAsString(buffer.toString());
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
