import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:synchronized/synchronized.dart';

import '../models/map_structure_annotation.dart';
import '../utils/firebase_ready.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';
import 'hive_db.dart';
import '../utils/device_id_helper.dart';
import '../models/sync_item.dart';
import 'sync/sync_queue_service.dart';
import '../core/di/dependency_injection.dart';
import 'package:uuid/uuid.dart';

/// Xaritadagi qo‘lda qo‘yilgan strike/dip belgilar (offline + Firestore).
class MapStructureRepository extends ChangeNotifier {
  Box<MapStructureAnnotation>? _box;

  List<MapStructureAnnotation> _items = [];
  List<MapStructureAnnotation> get annotations => _items.where((a) => !a.isDeleted).toList();

  final SyncQueueService _syncQueue = sl<SyncQueueService>();

  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;
  final _lock = Lock();

  Future<void> init() async {
    if (!Hive.isBoxOpen(HiveDb.mapStructureBox)) {
      ErrorLogger.record(
        StateError('Hive ${HiveDb.mapStructureBox} ochilmagan'),
        StackTrace.current,
        customMessage: 'MapStructureRepository.init',
      );
      return;
    }
    _box = Hive.box<MapStructureAnnotation>(HiveDb.mapStructureBox);
    _items = _box!.values.toList();
    notifyListeners();
    _attachRemote();
  }

  void _attachRemote() {
    _remoteSub?.cancel();
    final fs = _firestore;
    if (fs == null) return;
    _remoteSub = fs.collection('map_structure_annotations').snapshots().listen(
        (snap) async {
      var changed = false;
      for (final doc in snap.docs) {
        final m = doc.data();
        if (m.isEmpty) continue;
        final a = MapStructureAnnotation.fromMap(m);
        if (a.id.isEmpty) continue;
        if (!(_box?.containsKey(a.id) ?? false)) {
          await _box?.put(a.id, a);
          changed = true;
        }
      }
      if (changed) {
        _items = _box?.values.toList() ?? [];
        notifyListeners();
      }
    }, onError: (e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MapStructureRepository stream error');
    });
  }

  Future<MapStructureAnnotation> _stamp(MapStructureAnnotation a,
      {bool increment = false}) async {
    final deviceId = await DeviceIdHelper.getDeviceId();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return MapStructureAnnotation.fromMap({
      ...a.toMap(),
      'version': increment ? (a.version + 1) : a.version,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': uid,
      'updatedByDeviceId': deviceId,
    });
  }

  /// Legacy annotatsiya: `ownerUid` bo‘lmasa, avval claim.
  Future<void> _ensureAnnotationOwnerClaim(String docId) async {
    final fs = _firestore;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (fs == null || uid == null || !isFirebaseCoreReady) return;
    try {
      final snap = await NetworkExecutor.execute(
        () => fs.collection('map_structure_annotations').doc(docId).get(),
        actionName: 'Get Annotation Claim',
        maxRetries: 2,
      );
      if (!snap.exists) return;
      final v = snap.data()?['ownerUid'];
      if (v != null && v.toString().isNotEmpty) return;

      await NetworkExecutor.execute(
        () => fs
            .collection('map_structure_annotations')
            .doc(docId)
            .update({'ownerUid': uid}),
        actionName: 'Claim Annotation',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MapStructureRepository._ensureAnnotationOwnerClaim');
    }
  }

  Future<void> addAnnotation(MapStructureAnnotation a, {UpdateSource source = UpdateSource.local}) async {
    await _lock.synchronized(() async {
      final stamped = await _stamp(a);
      await _box!.put(stamped.id, stamped);

      if (source == UpdateSource.local) {
        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'map_annotation',
          entityId: stamped.id,
          payload: stamped.toMap(),
          version: stamped.version,
          operation: SyncOperation.create,
          requestId: const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      }

      _items = _box!.values.toList();
      notifyListeners();
    });
  }

  Future<void> updateAnnotation(MapStructureAnnotation a,
      {UpdateSource source = UpdateSource.local, String? customRequestId}) async {
    await _lock.synchronized(() async {
      final stamped = await _stamp(a, increment: source == UpdateSource.local);
      await _box!.put(stamped.id, stamped);

      if (source == UpdateSource.local) {
        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'map_annotation',
          entityId: stamped.id,
          payload: stamped.toMap(),
          version: stamped.version,
          operation: SyncOperation.update,
          requestId: customRequestId ?? const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      }

      _items = _box!.values.toList();
      notifyListeners();
    });
  }

  Future<void> deleteAnnotation(String id, {UpdateSource source = UpdateSource.local}) async {
    await _lock.synchronized(() async {
      final a = _box!.get(id);
      if (a == null || a.isDeleted) return;

      if (source == UpdateSource.local) {
        final deleted = a.copyWith(isDeleted: true);
        await _box!.put(id, deleted);

        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'map_annotation',
          entityId: id,
          payload: {},
          version: a.version,
          operation: SyncOperation.delete,
          requestId: const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      } else {
        await _box!.delete(id);
      }

      _items = _box!.values.toList();
      notifyListeners();
    });
  }





  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }
}
