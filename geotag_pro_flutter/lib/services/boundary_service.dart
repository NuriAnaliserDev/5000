import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';

import '../models/boundary_polygon.dart';
import '../utils/parsers/kml_parser.dart';
import '../utils/parsers/dxf_parser.dart';

class BoundaryImportResult {
  final String extension;
  final int importedCount;
  final int skippedCount;
  final bool normalizedCoordinates;

  const BoundaryImportResult({
    required this.extension,
    required this.importedCount,
    required this.skippedCount,
    required this.normalizedCoordinates,
  });
}

class BoundaryService extends ChangeNotifier {
  List<BoundaryPolygon> _boundaries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BoundaryPolygon> get boundaries => _boundaries;

  BoundaryService() {
    _initCloudSync();
  }

  void _initCloudSync() {
    _firestore.collection('global_boundaries').snapshots().listen((snapshot) {
      _boundaries = snapshot.docs
          .map((doc) => BoundaryPolygon.fromMap(
                doc.data(),
                id: doc.id,
              ))
          .toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint("Boundary Cloud Sync Error: $error");
    });
  }

  BoundaryPolygon? getActiveBoundary(LatLng point) {
    for (var b in _boundaries) {
      if (b.containsPoint(point)) return b;
    }
    return null;
  }

  BoundaryPolygon? getBoundaryAt(LatLng point) {
    for (var b in _boundaries) {
      if (b.containsPoint(point)) return b;
    }
    return null;
  }

  bool isInNonWorkZone(LatLng point) {
    final zone = getActiveBoundary(point);
    return zone != null && !zone.countsAsWorkTime;
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addPolygonFromPoints({
    required List<LatLng> points,
    required String name,
    required ZoneType zoneType,
    String? description,
  }) async {
    if (points.length < 3) {
      throw Exception("Polygon kamida 3 nuqtadan iborat bo'lishi kerak.");
    }
    final polygon = BoundaryPolygon(
      name: name,
      points: points,
      sourceFile: 'drawn',
      zoneType: zoneType,
      description: description,
    );
    try {
      await _firestore.collection('global_boundaries').add(polygon.toMap());
    } catch (e) {
      debugPrint("addPolygonFromPoints error: $e");
      rethrow;
    }
  }

  Future<void> updatePolygon({
    required String firestoreId,
    required String name,
    required ZoneType zoneType,
    String? description,
  }) async {
    try {
      await _firestore.collection('global_boundaries').doc(firestoreId).update({
        'name': name,
        'zoneType': zoneType.firestoreKey,
        'description': description,
        'countsAsWorkTime': zoneType.countsAsWorkTime,
      });
    } catch (e) {
      debugPrint("updatePolygon error: $e");
      rethrow;
    }
  }

  Future<void> deletePolygon(String firestoreId) async {
    try {
      await _firestore.collection('global_boundaries').doc(firestoreId).delete();
    } catch (e) {
      debugPrint("deletePolygon error: $e");
      rethrow;
    }
  }

  Future<void> clearAllPolygons() async {
    for (var b in _boundaries) {
      if (b.firestoreId != null) {
        await deletePolygon(b.firestoreId!);
      }
    }
  }

  Future<void> updatePolygonVertex(String firestoreId, int vertexIndex, LatLng newPos) async {
    final poly = _boundaries.firstWhere((b) => b.firestoreId == firestoreId);
    final newPoints = List<LatLng>.from(poly.points);
    newPoints[vertexIndex] = newPos;
    
    try {
      await _firestore.collection('global_boundaries').doc(firestoreId).update({
        'points': newPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      });
    } catch (e) {
      debugPrint("updatePolygonVertex error: $e");
    }
  }

  // ─── FILE IMPORT (DXF / KML) ───────────────────────────────────────────────

  Future<BoundaryImportResult?> importFileFromWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'dxf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) throw Exception("Fayl datasi o'qilmadi.");

      final content = utf8.decode(file.bytes!);
      final ext = file.extension?.toLowerCase() ?? '';
      final filename = file.name;

      List<BoundaryPolygon> newPolys = [];
      if (ext == 'kml') {
        newPolys = KmlParser.parse(content, filename);
      } else if (ext == 'dxf') {
        newPolys = DxfParser.parse(content, filename);
      }

      int imported = 0;
      int skipped = 0;
      bool normalized = false;

      for (final p in newPolys) {
        final normalizedPolygon = _normalizePolygonIfNeeded(p);
        if (normalizedPolygon == null || normalizedPolygon.points.length < 2) {
          skipped++;
          continue;
        }
        if (!identical(normalizedPolygon, p)) {
          normalized = true;
        }
        await _firestore.collection('global_boundaries').add(normalizedPolygon.toMap());
        imported++;
      }

      return BoundaryImportResult(
        extension: ext,
        importedCount: imported,
        skippedCount: skipped,
        normalizedCoordinates: normalized,
      );
    } catch (e) {
      debugPrint("Web Upload Error: $e");
      rethrow;
    }
  }

  BoundaryPolygon? _normalizePolygonIfNeeded(BoundaryPolygon polygon) {
    final pts = polygon.points;
    if (pts.isEmpty) return polygon;

    bool hasInvalidLat = false;
    bool hasInvalidLng = false;
    for (final p in pts) {
      if (p.latitude.abs() > 90) hasInvalidLat = true;
      if (p.longitude.abs() > 180) hasInvalidLng = true;
    }

    if (!hasInvalidLat && !hasInvalidLng) return polygon;

    final swapped = pts.map((p) => LatLng(p.longitude, p.latitude)).toList();
    bool swappedValid = true;
    for (final p in swapped) {
      if (p.latitude.abs() > 90 || p.longitude.abs() > 180) {
        swappedValid = false;
        break;
      }
    }
    if (!swappedValid) return null;

    return BoundaryPolygon(
      name: polygon.name,
      points: swapped,
      sourceFile: polygon.sourceFile,
      description: polygon.description,
      zoneType: polygon.zoneType,
      firestoreId: polygon.firestoreId,
    );
  }
}
