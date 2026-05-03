import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../../models/sync_item.dart';
import '../cloud_sync_service.dart';
import 'sync_queue_service.dart';

enum SyncEngineStatus { idle, syncing, error, noInternet }

class SyncProcessor extends ChangeNotifier {
  final SyncQueueService _queueService;
  final CloudSyncService _cloudSync;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _lock = Lock();
  bool _isRunning = false;
  
  SyncEngineStatus _status = SyncEngineStatus.idle;
  SyncEngineStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

  SyncProcessor(this._queueService, this._cloudSync);

  /// Stuck bo'lib qolgan (processing) itemlarni pendingga qaytarish
  Future<void> init() async {
    await _queueService.resetProcessingItems();
    // Start initial sync if online
    run();
  }

  /// Engine'ni yurgizish
  Future<void> run() async {
    if (_isRunning) return;
    
    // Internet tekshiruvi
    final hasInternet = await _cloudSync.hasRealInternet();
    if (!hasInternet) {
      _updateStatus(SyncEngineStatus.noInternet);
      return;
    }

    await _lock.synchronized(() async {
      if (_isRunning) return;
      _isRunning = true;
      _updateStatus(SyncEngineStatus.syncing);

      try {
        await _processQueue();
        _updateStatus(SyncEngineStatus.idle);
      } catch (e) {
        _lastError = e.toString();
        _updateStatus(SyncEngineStatus.error);
      } finally {
        _isRunning = false;
      }
    });
  }

  Future<void> _processQueue() async {
    while (true) {
      final items = _queueService.pendingItems;
      if (items.isEmpty) break;

      // FIFO: sequence bo'yicha eng kichigini olamiz
      final item = items.first;

      try {
        await _queueService.updateItemStatus(item, SyncStatus.processing);
        await _processItem(item);
        await _queueService.updateItemStatus(item, SyncStatus.done);
        await _queueService.removeItem(item); // Done bo'lgach o'chirib yuboramiz
      } catch (e) {
        await _handleError(item, e);
        // Agar kritik xato bo'lsa (masalan internet uzilsa), navbatni to'xtatamiz
        if (e is FirebaseException && e.code == 'unavailable') break;
        // Bitta item xato bo'lsa, keyingisiga o'tish yoki to'xtash qarori
        // Hozircha tartib buzilmasligi uchun to'xtaymiz
        break; 
      }
    }
  }

  Future<void> _processItem(SyncItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Firestore Reference aniqlash
    final docRef = _getDocRef(item, uid);

    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await docRef.set({
          ...item.payload,
          'lastRequestId': item.requestId, // Idempotency
          'serverSyncedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        break;
      case SyncOperation.delete:
        // Bulk delete bo'lsa (projectName bo'yicha)
        if (item.entityType == 'project_stations') {
          await _handleBulkDelete(item, uid);
        } else {
          await docRef.delete();
        }
        break;
    }
  }

  DocumentReference _getDocRef(SyncItem item, String uid) {
    switch (item.entityType) {
      case 'station':
        return _firestore.collection('users').doc(uid).collection('stations').doc(item.entityId);
      case 'geological_line':
        return _firestore.collection('geological_lines').doc(item.entityId);
      case 'map_annotation':
        return _firestore.collection('map_structure_annotations').doc(item.entityId);
      default:
        throw Exception('Unknown entity type: ${item.entityType}');
    }
  }

  Future<void> _handleBulkDelete(SyncItem item, String uid) async {
    final projectName = item.entityId;
    final batch = _firestore.batch();
    
    final snapshots = await _firestore
        .collection('users')
        .doc(uid)
        .collection('stations')
        .where('project', isEqualTo: projectName)
        .get();
        
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  Future<void> _handleError(SyncItem item, dynamic error) async {
    debugPrint('Sync Error for ${item.entityId}: $error');
    
    bool isPermanent = false;
    if (error is FirebaseException) {
      // Retry qilib bo'lmaydigan xatolar
      if (error.code == 'permission-denied' || 
          error.code == 'invalid-argument') {
        isPermanent = true;
      }
    }

    if (isPermanent || item.retryCount >= SyncItem.maxRetries) {
      await _queueService.updateItemStatus(item, SyncStatus.permanentlyFailed);
    } else {
      item.retryCount++;
      await _queueService.updateItemStatus(item, SyncStatus.failed);
      // Exponential backoff keyinroq qo'shilishi mumkin
    }
  }

  void _updateStatus(SyncEngineStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
