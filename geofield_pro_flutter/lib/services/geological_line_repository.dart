import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:synchronized/synchronized.dart';

import '../models/geological_line.dart';
import '../utils/firebase_ready.dart';
import '../core/di/dependency_injection.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';
import '../utils/device_id_helper.dart';
import '../models/sync_item.dart';
import 'sync/sync_queue_service.dart';
import 'package:uuid/uuid.dart';

/// Repository for geological linework features (faults, contacts, etc.)
/// Backed by a Hive box for offline-first storage.
class GeologicalLineRepository extends ChangeNotifier {
  static const _boxName = 'geologicalLines';
  Box<GeologicalLine>? _box;

  List<GeologicalLine> _lines = [];
  List<GeologicalLine> get lines => _lines.where((l) => !l.isDeleted).toList();

  final SyncQueueService _syncQueue = sl<SyncQueueService>();

  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription? _remoteSubscription;
  final _lock = Lock();

  Future<void> init() async {
    _box = await Hive.openBox<GeologicalLine>(_boxName);
    _lines = _box!.values.toList();
    notifyListeners();

    _initRemoteSync();
  }

  void _initRemoteSync() {
    _remoteSubscription?.cancel();
    final fs = _firestore;
    if (fs == null) return;
    _remoteSubscription =
        fs.collection('geological_lines').snapshots().listen((snapshot) async {
      bool changed = false;
      for (var doc in snapshot.docs) {
        final remoteLine = GeologicalLine.fromMap(doc.data());
        if (!_box!.containsKey(remoteLine.id)) {
          await _box!.put(remoteLine.id, remoteLine);
          changed = true;
        }
      }
      if (changed) {
        _lines = _box!.values.toList();
        notifyListeners();
      }
    }, onError: (e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'GeologicalLineRepository stream error');
    });
  }

  Future<GeologicalLine> _stamp(GeologicalLine line,
      {bool increment = false}) async {
    final deviceId = await DeviceIdHelper.getDeviceId();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return GeologicalLine.fromMap({
      ...line.toMap(),
      'version': increment ? (line.version + 1) : line.version,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': uid,
      'updatedByDeviceId': deviceId,
    });
  }

  /// Add a new geological line and persist it.
  Future<void> addLine(GeologicalLine line,
      {UpdateSource source = UpdateSource.local}) async {
    await _lock.synchronized(() async {
      final stamped = await _stamp(line);
      await _box!.put(stamped.id, stamped);

      if (source == UpdateSource.local) {
        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'geological_line',
          entityId: stamped.id,
          payload: stamped.toMap(),
          version: stamped.version,
          operation: SyncOperation.create,
          requestId: const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      }

      _lines = _box!.values.toList();
      notifyListeners();
    });
  }

  /// Update an existing line by its id.
  Future<void> updateLine(GeologicalLine line,
      {UpdateSource source = UpdateSource.local,
      String? customRequestId}) async {
    await _lock.synchronized(() async {
      final stamped =
          await _stamp(line, increment: source == UpdateSource.local);
      await _box!.put(stamped.id, stamped);

      if (source == UpdateSource.local) {
        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'geological_line',
          entityId: stamped.id,
          payload: stamped.toMap(),
          version: stamped.version,
          operation: SyncOperation.update,
          requestId: customRequestId ?? const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      }

      _lines = _box!.values.toList();
      notifyListeners();
    });
  }

  /// Legacy: `ownerUid` bo‘lmasa, bitta maydon bilan claim (Firestore qoidasi).
  Future<void> _ensureLineOwnerClaim(String docId) async {
    final fs = _firestore;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (fs == null || uid == null || !isFirebaseCoreReady) return;
    try {
      final snap = await NetworkExecutor.execute(
        () => fs.collection('geological_lines').doc(docId).get(),
        actionName: 'Get Line Claim',
        maxRetries: 2,
      );
      if (!snap.exists) return;
      final v = snap.data()?['ownerUid'];
      if (v != null && v.toString().isNotEmpty) return;

      await NetworkExecutor.execute(
        () => fs
            .collection('geological_lines')
            .doc(docId)
            .update({'ownerUid': uid}),
        actionName: 'Claim Geological Line',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: '_ensureLineOwnerClaim error');
    }
  }

  /// Delete a line by its id.
  Future<void> deleteLine(String id,
      {UpdateSource source = UpdateSource.local}) async {
    await _lock.synchronized(() async {
      final line = _box!.get(id);
      if (line == null || line.isDeleted) return;

      if (source == UpdateSource.local) {
        // Soft delete locally
        final deleted = line.copyWith(isDeleted: true);
        await _box!.put(id, deleted);

        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'geological_line',
          entityId: id,
          payload: {},
          version: line.version,
          operation: SyncOperation.delete,
          requestId: const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      } else {
        // Hard delete if it's a remote instruction
        await _box!.delete(id);
      }

      _lines = _box!.values.toList();
      notifyListeners();
    });
  }

  /// Get all lines for a given project.
  List<GeologicalLine> getByProject(String project) {
    return _lines.where((l) => l.project == project).toList();
  }

  /// Get all lines regardless of project.
  List<GeologicalLine> getAllLines() => _lines;

  /// Clear all lines (use with caution — irreversible).
  Future<void> clearAll() async {
    await _box!.clear();
    _lines = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _remoteSubscription?.cancel();
    super.dispose();
  }
}
