import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/map_structure_annotation.dart';
import '../utils/firebase_ready.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';

/// Xaritadagi qo‘lda qo‘yilgan strike/dip belgilar (offline + Firestore).
class MapStructureRepository extends ChangeNotifier {
  static const _boxName = 'map_structure_annotations';
  Box<MapStructureAnnotation>? _box;

  List<MapStructureAnnotation> _items = [];
  List<MapStructureAnnotation> get annotations => List.unmodifiable(_items);

  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;

  Future<void> init() async {
    _box = await Hive.openBox<MapStructureAnnotation>(_boxName);
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

  Future<void> addAnnotation(MapStructureAnnotation a) async {
    await _box!.put(a.id, a);
    _items = _box!.values.toList();
    notifyListeners();
    if (!isFirebaseCoreReady) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final fs = _firestore;
    if (fs == null) return;
    try {
      await NetworkExecutor.execute(
        () => fs.collection('map_structure_annotations').doc(a.id).set({
          ...a.toMap(),
          'ownerUid': uid,
        }, SetOptions(merge: true)),
        actionName: 'Add Annotation',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MapStructureRepository upload error');
    }
  }

  Future<void> deleteAnnotation(String id) async {
    await _box!.delete(id);
    _items = _box!.values.toList();
    notifyListeners();
    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureAnnotationOwnerClaim(id);
      await NetworkExecutor.execute(
        () => fs.collection('map_structure_annotations').doc(id).delete(),
        actionName: 'Delete Annotation',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st,
          customMessage: 'MapStructureRepository delete remote error');
    }
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }
}
