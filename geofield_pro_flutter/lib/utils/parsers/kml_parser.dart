import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';
import '../../models/boundary_polygon.dart';

class KmlParser {
  static List<BoundaryPolygon> parse(String content, String filename) {
    List<BoundaryPolygon> extracted = [];
    try {
      final document = XmlDocument.parse(content);
      final placemarks = document.findAllElements('Placemark');

      for (var placemark in placemarks) {
        final nameEl = placemark.findElements('name').firstOrNull?.innerText;
        final name = nameEl ?? 'KML Chizma ${extracted.length + 1}';
        
        // Handle Polygons
        final polygonNode = placemark.findAllElements('Polygon').firstOrNull;
        if (polygonNode != null) {
          final coordsNode = polygonNode.findAllElements('coordinates').firstOrNull;
          if (coordsNode != null) {
            final points = _parseCoordinatesString(coordsNode.innerText);
            if (points.isNotEmpty) {
              extracted.add(BoundaryPolygon(
                name: name,
                points: points,
                sourceFile: filename,
                description: "Imported from $filename",
                zoneType: ZoneType.workArea,
              ));
            }
          }
        }
        
        // Handle LineStrings
        final lines = placemark.findAllElements('LineString');
        for (var line in lines) {
          final coordsNode = line.findAllElements('coordinates').firstOrNull;
          if (coordsNode != null) {
            final points = _parseCoordinatesString(coordsNode.innerText);
            if (points.isNotEmpty) {
               extracted.add(BoundaryPolygon(
                name: "$name (Line)",
                points: points,
                sourceFile: filename,
                zoneType: ZoneType.base,
              ));
            }
          }
        }
      }
      return extracted;
    } catch (e) {
      throw Exception('KML formatini oqishda xatolik: $e');
    }
  }

  static List<LatLng> _parseCoordinatesString(String text) {
    final List<LatLng> result = [];
    final pairs = text.trim().split(RegExp(r'\s+'));
    for (var pairStr in pairs) {
      final parts = pairStr.split(',');
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[0].trim());
        final lat = double.tryParse(parts[1].trim());
        if (lng != null && lat != null) {
          result.add(LatLng(lat, lng));
        }
      }
    }
    return result;
  }
}
