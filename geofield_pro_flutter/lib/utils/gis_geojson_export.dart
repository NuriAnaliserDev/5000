import 'dart:convert';

import '../models/boundary_polygon.dart';
import '../models/geological_line.dart';

/// Geologik chiziqlar va chegaralarni WGS-84 GeoJSON faylga aylantiradi.
class GisGeoJsonExport {
  GisGeoJsonExport._();

  static String buildString({
    required List<GeologicalLine> lines,
    required List<BoundaryPolygon> boundaries,
  }) {
    final features = <Map<String, dynamic>>[];
    for (final b in boundaries) {
      if (b.points.length < 2) continue;
      final ring =
          b.points.map((p) => <double>[p.longitude, p.latitude]).toList();
      if (b.points.length >= 3) {
        if (ring.isNotEmpty &&
            (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
          ring.add([ring.first[0], ring.first[1]]);
        }
        features.add({
          'type': 'Feature',
          'properties': {
            'name': b.name,
            'source': 'boundary',
            'zoneType': b.zoneType.firestoreKey,
            'description': b.description,
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
        });
      } else {
        features.add({
          'type': 'Feature',
          'properties': {
            'name': b.name,
            'source': 'boundary_line',
            'zoneType': b.zoneType.firestoreKey,
          },
          'geometry': {
            'type': 'LineString',
            'coordinates': ring,
          },
        });
      }
    }
    for (final l in lines) {
      if (l.lats.isEmpty) continue;
      final coords = <List<double>>[];
      for (var i = 0; i < l.lats.length; i++) {
        coords.add([l.lngs[i], l.lats[i]]);
      }
      if (l.isClosed && l.lats.length >= 3) {
        if (coords.isNotEmpty) {
          final f = coords.first;
          final la = coords.last;
          if (f[0] != la[0] || f[1] != la[1]) {
            coords.add([f[0], f[1]]);
          }
        }
        features.add({
          'type': 'Feature',
          'properties': {
            'name': l.name,
            'lineType': l.lineType,
            'notes': l.notes,
            'source': 'geological_line',
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coords],
          },
        });
      } else {
        features.add({
          'type': 'Feature',
          'properties': {
            'name': l.name,
            'lineType': l.lineType,
            'notes': l.notes,
            'source': 'geological_line',
          },
          'geometry': {
            'type': 'LineString',
            'coordinates': coords,
          },
        });
      }
    }
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });
  }
}
