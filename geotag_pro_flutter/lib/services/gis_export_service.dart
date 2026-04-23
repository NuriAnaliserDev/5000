import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';

import '../models/station.dart';
import '../models/geological_line.dart';
import '../models/track_data.dart';

class GisExportService {
  final List<Station> stations;
  final List<GeologicalLine> geoLines;
  final List<TrackData> tracks;

  GisExportService({
    required this.stations,
    required this.geoLines,
    required this.tracks,
  });

  /// 1. GeoJSON formatini yig'ish
  String generateGeoJSON() {
    final features = <Map<String, dynamic>>[];

    // Stations
    for (final s in stations) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [s.lng, s.lat, s.altitude]
        },
        "properties": {
          "id": s.name,
          "project": s.project,
          "strike": s.strike,
          "dip": s.dip,
          "azimuth": s.azimuth,
          "type": s.measurementType ?? "bedding",
          "rock_type": s.rockType ?? "",
          "desc": s.description ?? "",
        }
      });
    }

    // Geological Lines
    for (final l in geoLines) {
      if (l.lats.isEmpty) continue;
      final coords = <List<double>>[];
      for (int i = 0; i < l.lats.length; i++) {
        coords.add([l.lngs[i], l.lats[i]]); // [lng, lat]
      }
      
      // Close polygon if requested
      if (l.isClosed && coords.isNotEmpty && (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1])) {
         coords.add(coords.first);
      }

      features.add({
        "type": "Feature",
        "geometry": {
          "type": l.isClosed ? "Polygon" : "LineString",
          "coordinates": l.isClosed ? [coords] : coords
        },
        "properties": {
          "name": l.name,
          "type": l.lineType,
          "id": l.id,
        }
      });
    }

    // Tracks (GPS marshrutlar)
    for (final t in tracks) {
      if (t.points.isEmpty) continue;
      final coords = t.points.map((p) => [p.lng, p.lat, p.alt]).toList();
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": coords
        },
        "properties": {
          "name": t.name,
          "author": t.authorName ?? "Unknown",
          "distance": t.distanceMeters,
          "type": "track"
        }
      });
    }

    final geoJson = {
      "type": "FeatureCollection",
      "features": features
    };

    return jsonEncode(geoJson);
  }

  /// 2. Eng muhimi: DXF eksport algoritmi (AutoCAD qatlamlari bilan yagona fayl!)
  String generateDXF() {
    final buffer = StringBuffer();
    
    // Header
    buffer.write("  0\nSECTION\n  2\nENTITIES\n");

    // Nuqtalar (Stations)
    for (final s in stations) {
      buffer.write("  0\nPOINT\n");
      buffer.write("  8\nGeoField_Stations\n"); // Layer
      buffer.write(" 10\n${s.lng}\n 20\n${s.lat}\n 30\n${s.altitude}\n"); // Coordinates
      
      // Matni qo'shish (Station Code text on DXF)
      buffer.write("  0\nTEXT\n");
      buffer.write("  8\nGeoField_Station_Labels\n");
      buffer.write(" 10\n${s.lng + 0.0001}\n 20\n${s.lat + 0.0001}\n 30\n${s.altitude}\n");
      buffer.write(" 40\n0.001\n"); // Text height
      buffer.write("  1\n${s.name} (S${s.strike.toStringAsFixed(0)}/D${s.dip.toStringAsFixed(0)})\n");
    }

    // Chiziqlar (Geological Lines)
    for (final l in geoLines) {
      if (l.lats.isEmpty) continue;
      buffer.write("  0\nPOLYLINE\n");
      buffer.write("  8\nGeoField_Lines_${l.lineType}\n"); // Differ layers by line type
      buffer.write(" 66\n1\n"); // Vertices follow
      buffer.write(" 10\n0.0\n 20\n0.0\n 30\n0.0\n"); // Dummy base point
      if (l.isClosed) {
          buffer.write(" 70\n1\n"); // Closed polyline flag
      } else {
          buffer.write(" 70\n0\n");
      }
      
      for (int i = 0; i < l.lats.length; i++) {
        buffer.write("  0\nVERTEX\n");
        buffer.write("  8\nGeoField_Lines_${l.lineType}\n");
        buffer.write(" 10\n${l.lngs[i]}\n 20\n${l.lats[i]}\n 30\n0.0\n");
      }
      buffer.write("  0\nSEQEND\n");
    }

    // Tracks (Marshrut)
    for (final t in tracks) {
       if (t.points.isEmpty) continue;
       buffer.write("  0\nPOLYLINE\n");
       buffer.write("  8\nGeoField_Tracks\n");
       buffer.write(" 66\n1\n");
       buffer.write(" 10\n0.0\n 20\n0.0\n 30\n0.0\n");
       buffer.write(" 70\n0\n"); // Open
       
       for (final p in t.points) {
         buffer.write("  0\nVERTEX\n");
         buffer.write("  8\nGeoField_Tracks\n");
         buffer.write(" 10\n${p.lng}\n 20\n${p.lat}\n 30\n${p.alt}\n");
       }
       buffer.write("  0\nSEQEND\n");
    }

    // Footer
    buffer.write("  0\nENDSEC\n  0\nEOF\n");

    return buffer.toString();
  }

  /// 3. Hammasini ZIP qilib Share qilish (Zip exports together)
  Future<void> exportGisBundle() async {
    try {
      final geoJsonStr = generateGeoJSON();
      final dxfStr = generateDXF();
      
      final archive = Archive();
      archive.addFile(ArchiveFile('geofield_export.geojson', geoJsonStr.length, utf8.encode(geoJsonStr)));
      final dxfBytes = utf8.encode(dxfStr);
      archive.addFile(ArchiveFile('geofield_export.dxf', dxfBytes.length, dxfBytes));

      final zipData = ZipEncoder().encode(archive)!;
      
      final dir = await getApplicationDocumentsDirectory();
      final date = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/GeoField_GIS_Export_$date.zip');
      
      await file.writeAsBytes(zipData);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'GeoField Pro N - Barcha geologik nuqta, chiziq va marshrutlar (DXF va GeoJSON formadida)',
      );
    } catch (e) {
      debugPrint('GIS Export error: \$e');
      rethrow;
    }
  }
}
