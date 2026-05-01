import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/geological_line.dart';
import '../utils/firebase_ready.dart';

/// Repository for geological linework features (faults, contacts, etc.)
/// Backed by a Hive box for offline-first storage.
class GeologicalLineRepository extends ChangeNotifier {
  static const _boxName = 'geologicalLines';
  Box<GeologicalLine>? _box;

  List<GeologicalLine> _lines = [];
  List<GeologicalLine> get lines => List.unmodifiable(_lines);

  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription? _remoteSubscription;

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
    _remoteSubscription = fs
        .collection('geological_lines')
        .snapshots()
        .listen((snapshot) async {
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
    });
  }

  /// Add a new geological line and persist it.
  Future<void> addLine(GeologicalLine line) async {
    await _box!.put(line.id, line);
    _lines = _box!.values.toList();
    notifyListeners();
    _uploadLine(line);
  }

  /// Update an existing line by its id.
  Future<void> updateLine(GeologicalLine line) async {
    await _box!.put(line.id, line);
    _lines = _box!.values.toList();
    notifyListeners();
    _uploadLine(line);
  }

  /// Legacy: `ownerUid` bo‘lmasa, bitta maydon bilan claim (Firestore qoidasi).
  Future<void> _ensureLineOwnerClaim(String docId) async {
    final fs = _firestore;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (fs == null || uid == null || !isFirebaseCoreReady) return;
    try {
      final snap = await fs.collection('geological_lines').doc(docId).get();
      if (!snap.exists) return;
      final v = snap.data()?['ownerUid'];
      if (v != null && v.toString().isNotEmpty) return;
      await fs.collection('geological_lines').doc(docId).update({'ownerUid': uid});
    } catch (e) {
      debugPrint('_ensureLineOwnerClaim: $e');
    }
  }

  /// Delete a line by its id.
  Future<void> deleteLine(String id) async {
    await _box!.delete(id);
    _lines = _box!.values.toList();
    notifyListeners();
    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureLineOwnerClaim(id);
      await fs.collection('geological_lines').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting line from Firestore: $e');
    }
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

  Future<void> _uploadLine(GeologicalLine line) async {
    if (!isFirebaseCoreReady) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final fs = _firestore;
    if (fs == null) return;
    try {
      await _ensureLineOwnerClaim(line.id);
      await fs.collection('geological_lines').doc(line.id).set({
        ...line.toMap(),
        'ownerUid': uid,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error uploading line: $e');
    }
  }

  @override
  void dispose() {
    _remoteSubscription?.cancel();
    super.dispose();
  }
}
