import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/spatial_calculator.dart';

/// Zona turi — Dashboard'da ranglar va mantiq shu enum bilan boshqariladi.
enum ZoneType {
  workArea,   // Ishchi hudud — yashil
  cafeteria,  // Oshxona / ovqatlanish — to'q sariq
  restArea,   // Dam olish, karantin — sariq
  hazard,     // Xavfli zona — qizil
  base,       // Asosiy lager / baza — moviy
}

extension ZoneTypeExtension on ZoneType {
  String get label {
    switch (this) {
      case ZoneType.workArea:  return "Ish Hududi";
      case ZoneType.cafeteria: return "Oshxona";
      case ZoneType.restArea:  return "Dam Olish";
      case ZoneType.hazard:    return "Xavfli Zona";
      case ZoneType.base:      return "Baza / Lager";
    }
  }

  Color get color {
    switch (this) {
      case ZoneType.workArea:  return Colors.green;
      case ZoneType.cafeteria: return Colors.amber;
      case ZoneType.restArea:  return Colors.orange;
      case ZoneType.hazard:    return Colors.red;
      case ZoneType.base:      return Colors.blue;
    }
  }

  /// Dashboard statistikasida ish vaqtiga kirmaydi (false = dam olish hududi)
  bool get countsAsWorkTime {
    switch (this) {
      case ZoneType.workArea:  return true;
      case ZoneType.cafeteria: return false;
      case ZoneType.restArea:  return false;
      case ZoneType.hazard:    return false;
      case ZoneType.base:      return false;
    }
  }

  String get firestoreKey {
    switch (this) {
      case ZoneType.workArea:  return "workArea";
      case ZoneType.cafeteria: return "cafeteria";
      case ZoneType.restArea:  return "restArea";
      case ZoneType.hazard:    return "hazard";
      case ZoneType.base:      return "base";
    }
  }

  static ZoneType fromString(String? s) {
    switch (s) {
      case "workArea":  return ZoneType.workArea;
      case "cafeteria": return ZoneType.cafeteria;
      case "restArea":  return ZoneType.restArea;
      case "hazard":    return ZoneType.hazard;
      case "base":      return ZoneType.base;
      default:          return ZoneType.workArea;
    }
  }
}

class BoundaryPolygon {
  /// Firestore hujjat ID'si (null = lokal, hali saqlanmagan)
  final String? firestoreId;
  final String name;
  final List<LatLng> points;
  final String sourceFile;
  final ZoneType zoneType;
  final String? description;
  final double areaSqMeters;
  final double perimeterMeters;

  BoundaryPolygon({
    this.firestoreId,
    required this.name,
    required this.points,
    this.sourceFile = 'drawn',
    this.zoneType = ZoneType.workArea,
    this.description,
  })  : areaSqMeters = SpatialCalculator.calculateArea(points),
        perimeterMeters = SpatialCalculator.calculatePerimeter(points);

  String? get id => firestoreId;

  Color get displayColor => zoneType.color;
  bool get countsAsWorkTime => zoneType.countsAsWorkTime;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sourceFile': sourceFile,
      'zoneType': zoneType.firestoreKey,
      'description': description,
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'areaSqMeters': areaSqMeters,
      'perimeterMeters': perimeterMeters,
      'countsAsWorkTime': countsAsWorkTime,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }

  factory BoundaryPolygon.fromMap(Map<String, dynamic> map, {String? id}) {
    final pts = (map['points'] as List<dynamic>?)
            ?.map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList() ??
        [];
    return BoundaryPolygon(
      firestoreId: id,
      name: map['name'] ?? 'Nomlanmagan Zona',
      points: pts,
      sourceFile: map['sourceFile'] ?? 'cloud',
      zoneType: ZoneTypeExtension.fromString(map['zoneType'] as String?),
      description: map['description'] as String?,
    );
  }

  /// Sferik Winding Number algoritmi — katta geografik poligonlar uchun to'g'ri ishlaydi.
  bool containsPoint(LatLng point) {
    if (points.length < 3) return false;

    final lat = point.latitude;
    final lng = point.longitude;
    int windingNumber = 0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      final lat1 = p1.latitude;
      final lng1 = p1.longitude;
      final lat2 = p2.latitude;
      final lng2 = p2.longitude;

      if (lat1 <= lat) {
        if (lat2 > lat) {
          if (_isLeft(lng1, lat1, lng2, lat2, lng, lat) > 0) windingNumber++;
        }
      } else {
        if (lat2 <= lat) {
          if (_isLeft(lng1, lat1, lng2, lat2, lng, lat) < 0) windingNumber--;
        }
      }
    }
    return windingNumber != 0;
  }

  static double _isLeft(
    double x1, double y1,
    double x2, double y2,
    double px, double py,
  ) {
    return (x2 - x1) * (py - y1) - (px - x1) * (y2 - y1);
  }
}
