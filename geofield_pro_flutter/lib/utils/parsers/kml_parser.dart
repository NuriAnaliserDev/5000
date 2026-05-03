import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../models/boundary_polygon.dart';
import '../../core/error/app_error.dart';

class KmlParser {
  static List<BoundaryPolygon> parse(String content, String filename) {
    final extracted = <BoundaryPolygon>[];
    try {
      final doc = XmlDocument.parse(content);
      for (final pm in doc.descendants.whereType<XmlElement>()) {
        if (pm.name.local != 'Placemark') continue;
        _extractPlacemark(pm, filename, extracted);
      }
      return extracted;
    } catch (e) {
      throw AppError('KML formatini oqishda xatolik: $e', category: ErrorCategory.validation);
    }
  }

  static String _placemarkBaseName(XmlElement placemark, int fallbackIndex) {
    for (final c in placemark.childElements) {
      if (c.name.local == 'name') {
        final t = c.innerText.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return 'KML Chizma ${fallbackIndex + 1}';
  }

  static void _extractPlacemark(
    XmlElement placemark,
    String filename,
    List<BoundaryPolygon> out,
  ) {
    final baseName = _placemarkBaseName(placemark, out.length);

    void polygonFrom(XmlElement polygonEl) {
      for (final ring in polygonEl.findAllElements('LinearRing')) {
        final cn = ring.findElements('coordinates').firstOrNull;
        if (cn == null) continue;
        final pts = _parseCoordinatesString(cn.innerText);
        if (pts.length >= 3) {
          out.add(BoundaryPolygon(
            name: baseName,
            points: pts,
            sourceFile: filename,
            description: 'Imported from $filename',
            zoneType: ZoneType.workArea,
          ));
          return;
        }
      }
      final cn = polygonEl.findAllElements('coordinates').firstOrNull;
      if (cn != null) {
        final pts = _parseCoordinatesString(cn.innerText);
        if (pts.length >= 3) {
          out.add(BoundaryPolygon(
            name: baseName,
            points: pts,
            sourceFile: filename,
            description: 'Imported from $filename',
            zoneType: ZoneType.workArea,
          ));
        }
      }
    }

    void lineFrom(XmlElement lineEl) {
      final cn = lineEl.findAllElements('coordinates').firstOrNull;
      if (cn == null) return;
      final pts = _parseCoordinatesString(cn.innerText);
      if (pts.length < 2) return;
      out.add(BoundaryPolygon(
        name: '$baseName (Line)',
        points: pts,
        sourceFile: filename,
        zoneType: ZoneType.base,
      ));
    }

    void pointFrom(XmlElement pt) {
      final cn = pt.findAllElements('coordinates').firstOrNull;
      if (cn == null) return;
      final pts = _parseCoordinatesString(cn.innerText);
      if (pts.isEmpty) return;
      final p = pts.first;
      const eps = 0.000002;
      out.add(BoundaryPolygon(
        name: '$baseName (Point)',
        points: [p, LatLng(p.latitude + eps, p.longitude + eps)],
        sourceFile: filename,
        zoneType: ZoneType.base,
      ));
    }

    void walk(XmlElement el) {
      switch (el.name.local) {
        case 'Polygon':
          polygonFrom(el);
          return;
        case 'LineString':
          lineFrom(el);
          return;
        case 'Point':
          pointFrom(el);
          return;
        case 'MultiGeometry':
          for (final c in el.childElements) {
            walk(c);
          }
          return;
        default:
          for (final c in el.childElements) {
            walk(c);
          }
      }
    }

    for (final c in placemark.childElements) {
      walk(c);
    }
  }

  static List<LatLng> _parseCoordinatesString(String text) {
    final result = <LatLng>[];
    for (final pairStr in text.trim().split(RegExp(r'\s+'))) {
      if (pairStr.isEmpty) continue;
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
