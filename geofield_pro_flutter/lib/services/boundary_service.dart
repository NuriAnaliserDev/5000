import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/boundary_polygon.dart';
import '../utils/firebase_ready.dart';
import '../utils/parsers/dxf_parser.dart';
import '../utils/parsers/geojson_import_parser.dart';
import '../utils/parsers/gpkg_import_parser.dart';
import '../utils/parsers/kml_parser.dart';
import '../utils/parsers/shp_shapefile_parser.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';
import '../core/error/app_error.dart';

class BoundaryImportResult {
  final String extension;
  final int importedCount;
  final int skippedCount;

  /// WGS-84 tekshiruvidan keyin rad etilgan (UTM/koordinata buzilgan)
  final int skippedInvalidCoordinates;

  /// Nuqtalar soni kamida 2 emas
  final int skippedTooFewPoints;
  final bool normalizedCoordinates;

  /// Xarita oynasini ushbu importga yig‘ish (bo‘sh bo‘lmasa).
  final List<LatLng> fitPoints;

  const BoundaryImportResult({
    required this.extension,
    required this.importedCount,
    required this.skippedCount,
    this.skippedInvalidCoordinates = 0,
    this.skippedTooFewPoints = 0,
    required this.normalizedCoordinates,
    this.fitPoints = const [],
  });
}

class BoundaryService extends ChangeNotifier {
  static const _uuid = Uuid();

  /// Firestore’dan kelgan qatlam
  List<BoundaryPolygon> _cloudBoundaries = [];

  /// Login / Firebase bo‘lmasa yoki import lokal saqlangan
  final List<BoundaryPolygon> _localBoundaries = [];

  FirebaseFirestore? get _firestore => firestoreOrNull;

  String? get _currentUid {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Legacy chegaralar: `createdByUid` bo‘lmasa, avvalo faqat shu maydonni yozadi (Firestore claim qoidasi).
  Future<void> _ensureGlobalBoundaryCreatorClaim(String docId) async {
    final fs = _firestore;
    final uid = _currentUid;
    if (fs == null || uid == null) return;
    try {
      final snap = await NetworkExecutor.execute(
        () => fs.collection('global_boundaries').doc(docId).get(),
        actionName: 'Get Boundary Claim',
        maxRetries: 2,
      );
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final v = data['createdByUid'];
      if (v != null && v.toString().isNotEmpty) return;
      
      await NetworkExecutor.execute(
        () => fs
            .collection('global_boundaries')
            .doc(docId)
            .update({'createdByUid': uid}),
        actionName: 'Claim Boundary',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: '_ensureGlobalBoundaryCreatorClaim');
    }
  }

  List<BoundaryPolygon> get boundaries => List<BoundaryPolygon>.unmodifiable(
      [..._cloudBoundaries, ..._localBoundaries]);

  BoundaryService() {
    _initCloudSync();
  }

  void _initCloudSync() {
    final fs = _firestore;
    if (fs == null) return;
    fs.collection('global_boundaries').snapshots().listen((snapshot) {
      _cloudBoundaries = snapshot.docs
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

  static String _decodeImportText(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  BoundaryPolygon? getActiveBoundary(LatLng point) {
    for (var b in boundaries) {
      if (b.containsPoint(point)) return b;
    }
    return null;
  }

  BoundaryPolygon? getBoundaryAt(LatLng point) {
    for (var b in boundaries) {
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
      throw AppError("Polygon kamida 3 nuqtadan iborat bo'lishi kerak.", category: ErrorCategory.validation);
    }
    final uid = _currentUid;
    final fs = _firestore;

    if (uid == null || fs == null) {
      _localBoundaries.add(
        BoundaryPolygon(
          localId: _uuid.v4(),
          name: name,
          points: points,
          sourceFile: 'drawn',
          zoneType: zoneType,
          description: description,
        ),
      );
      notifyListeners();
      return;
    }

    final polygon = BoundaryPolygon(
      name: name,
      points: points,
      sourceFile: 'drawn',
      zoneType: zoneType,
      description: description,
    );
    try {
      await NetworkExecutor.execute(
        () => fs.collection('global_boundaries').add({
          ...polygon.toMap(),
          'createdByUid': uid,
        }),
        actionName: 'Add Boundary Polygon',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'addPolygonFromPoints error');
      rethrow;
    }
  }

  Future<void> updatePolygon({
    required String firestoreId,
    required String name,
    required ZoneType zoneType,
    String? description,
  }) async {
    final li = _localBoundaries.indexWhere((b) => b.id == firestoreId);
    if (li >= 0) {
      final poly = _localBoundaries[li];
      final newPts = List<LatLng>.from(poly.points);
      _localBoundaries[li] = BoundaryPolygon(
        firestoreId: poly.firestoreId,
        localId: poly.localId,
        name: name,
        points: newPts,
        sourceFile: poly.sourceFile,
        zoneType: zoneType,
        description: description,
      );
      notifyListeners();
      return;
    }
    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureGlobalBoundaryCreatorClaim(firestoreId);
      await NetworkExecutor.execute(
        () => fs.collection('global_boundaries').doc(firestoreId).update({
          'name': name,
          'zoneType': zoneType.firestoreKey,
          'description': description,
          'countsAsWorkTime': zoneType.countsAsWorkTime,
        }),
        actionName: 'Update Boundary Polygon',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'updatePolygon error');
    }
  }

  Future<void> deletePolygon(String polygonId) async {
    final before = _localBoundaries.length;
    _localBoundaries.removeWhere((b) => b.id == polygonId);
    if (_localBoundaries.length != before) {
      notifyListeners();
      return;
    }
    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureGlobalBoundaryCreatorClaim(polygonId);
      await NetworkExecutor.execute(
        () => fs.collection('global_boundaries').doc(polygonId).delete(),
        actionName: 'Delete Boundary Polygon',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'deletePolygon error');
    }
  }

  Future<void> clearAllPolygons() async {
    _localBoundaries.clear();
    final fs = _firestore;
    if (fs != null) {
      for (final b in List<BoundaryPolygon>.from(_cloudBoundaries)) {
        final id = b.firestoreId;
        if (id != null) {
          try {
            await _ensureGlobalBoundaryCreatorClaim(id);
            await NetworkExecutor.execute(
              () => fs.collection('global_boundaries').doc(id).delete(),
              actionName: 'Clear All Boundary Polygons',
              maxRetries: 2,
            );
          } catch (e, st) {
            ErrorLogger.record(e, st, customMessage: 'clearAllPolygons error');
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> updatePolygonVertex(
      String polygonId, int vertexIndex, LatLng newPos) async {
    final li = _localBoundaries.indexWhere((b) => b.id == polygonId);
    if (li >= 0) {
      final poly = _localBoundaries[li];
      if (vertexIndex < 0 || vertexIndex >= poly.points.length) return;
      final newPoints = List<LatLng>.from(poly.points);
      newPoints[vertexIndex] = newPos;
      _localBoundaries[li] = BoundaryPolygon(
        firestoreId: poly.firestoreId,
        localId: poly.localId,
        name: poly.name,
        points: newPoints,
        sourceFile: poly.sourceFile,
        zoneType: poly.zoneType,
        description: poly.description,
      );
      notifyListeners();
      return;
    }

    BoundaryPolygon? cloudPoly;
    for (final b in _cloudBoundaries) {
      if (b.firestoreId == polygonId) {
        cloudPoly = b;
        break;
      }
    }
    if (cloudPoly == null) return;
    if (vertexIndex < 0 || vertexIndex >= cloudPoly.points.length) return;
    final newPoints = List<LatLng>.from(cloudPoly.points);
    newPoints[vertexIndex] = newPos;

    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureGlobalBoundaryCreatorClaim(polygonId);
      await NetworkExecutor.execute(
        () => fs.collection('global_boundaries').doc(polygonId).update({
          'points': newPoints
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        }),
        actionName: 'Update Polygon Vertex',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'updatePolygonVertex error');
    }
  }

  // ─── FILE IMPORT (DXF / KML) ───────────────────────────────────────────────

  Future<BoundaryImportResult?> importFileFromWeb({
    double? hintLatitude,
    double? hintLongitude,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'dxf', 'geojson', 'json', 'shp', 'gpkg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) throw AppError("Fayl datasi o'qilmadi.", category: ErrorCategory.validation);

      final ext = file.extension?.toLowerCase() ?? '';
      final filename = file.name;

      List<BoundaryPolygon> newPolys = [];
      if (ext == 'kml' || ext == 'dxf' || ext == 'geojson' || ext == 'json') {
        final content = _decodeImportText(Uint8List.fromList(file.bytes!));
        if (ext == 'kml') {
          newPolys = KmlParser.parse(content, filename);
        } else if (ext == 'dxf') {
          newPolys = DxfParser.parse(
            content,
            filename,
            hintLatitude: hintLatitude,
            hintLongitude: hintLongitude,
          );
        } else {
          newPolys = GeojsonImportParser.parse(content, filename);
        }
      } else if (ext == 'shp') {
        newPolys =
            ShpShapefileParser.parse(Uint8List.fromList(file.bytes!), filename);
      } else if (ext == 'gpkg') {
        if (kIsWeb) {
          throw AppError(
              "GeoPackage (.gpkg) brauzerda import qilib bo'lmaydi (SQLite yo'q).", category: ErrorCategory.validation);
        }
        final dir = await getTemporaryDirectory();
        final tmp = io.File(
          p.join(dir.path,
              'gpkg_import_${DateTime.now().millisecondsSinceEpoch}.gpkg'),
        );
        await tmp.writeAsBytes(file.bytes!);
        try {
          newPolys = await GpkgImportParser.parseFile(tmp.path);
        } finally {
          if (tmp.existsSync()) {
            unawaited(tmp.delete());
          }
        }
      } else {
        newPolys = [];
      }

      int imported = 0;
      int skipped = 0;
      int skippedInvalid = 0;
      int skippedFew = 0;
      bool normalized = false;
      final List<LatLng> allFit = [];
      final importUid = _currentUid;
      final fs = _firestore;

      for (final p in newPolys) {
        final normalizedPolygon = _normalizePolygonIfNeeded(p);
        if (normalizedPolygon == null) {
          skippedInvalid++;
          skipped++;
          continue;
        }
        if (normalizedPolygon.points.length < 2) {
          skippedFew++;
          skipped++;
          continue;
        }
        if (!identical(normalizedPolygon, p)) {
          normalized = true;
        }
        if (importUid != null && fs != null) {
          await NetworkExecutor.execute(
            () => fs.collection('global_boundaries').add({
              ...normalizedPolygon.toMap(),
              'createdByUid': importUid,
            }),
            actionName: 'Import Boundary Polygon',
            maxRetries: 2,
          );
        } else {
          _localBoundaries.add(
            BoundaryPolygon(
              localId: _uuid.v4(),
              name: normalizedPolygon.name,
              points: normalizedPolygon.points,
              sourceFile: normalizedPolygon.sourceFile,
              zoneType: normalizedPolygon.zoneType,
              description: normalizedPolygon.description,
            ),
          );
        }
        allFit.addAll(normalizedPolygon.points);
        imported++;
      }
      if (importUid == null || fs == null) {
        if (imported > 0) {
          notifyListeners();
        }
      }

      return BoundaryImportResult(
        extension: ext,
        importedCount: imported,
        skippedCount: skipped,
        skippedInvalidCoordinates: skippedInvalid,
        skippedTooFewPoints: skippedFew,
        normalizedCoordinates: normalized,
        fitPoints: allFit,
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
      localId: polygon.localId,
    );
  }
}
