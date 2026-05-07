import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:synchronized/synchronized.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math';
import '../../core/config/app_features.dart';
import '../../core/diagnostics/log_channels.dart';
import '../../models/sync_item.dart';
import '../cloud_sync_service.dart';
import 'sync_queue_service.dart';
import 'conflict_queue_service.dart';
import '../../models/sync_conflict.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

enum SyncEngineStatus { idle, syncing, error, noInternet }

class SyncProcessor extends ChangeNotifier {
  final SyncQueueService _queueService;
  final CloudSyncService _cloudSync;
  final ConflictQueueService _conflictService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  final _lock = Lock();
  bool _isRunning = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  
  SyncEngineStatus _status = SyncEngineStatus.idle;
  SyncEngineStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

  // Telemetry
  int _successCount = 0;
  int _failureCount = 0;
  int _conflictCount = 0;
  
  int get successCount => _successCount;
  int get failureCount => _failureCount;
  int get conflictCount => _conflictCount;

  SyncProcessor(
    this._queueService, 
    this._cloudSync, 
    this._conflictService, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Stuck bo'lib qolgan (processing) itemlarni pendingga qaytarish
  Future<void> init() async {
    await _queueService.resetProcessingItems();

    if (!AppFeatures.enableCloudSync) {
      if (kDebugMode) {
        debugPrint(
          '${DiagLogChannel.sync.prefix} SyncProcessor: fon sinxron muzlatilgan.',
        );
      }
      return;
    }

    // Internet o'zgarganda avtomatik ishga tushirish
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        run();
      } else {
        _updateStatus(SyncEngineStatus.noInternet);
      }
    });

    run();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Engine'ni yurgizish
  Future<void> run() async {
    if (!AppFeatures.enableCloudSync) return;
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
        // Memory Safety: Har sync tsiklidan keyin boxni siqish
        await Hive.box<SyncItem>('sync_queue').compact();
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
        
        // 1. Payload size check
        if (!_checkPayloadLimit(item)) {
          throw Exception('Payload size too large (>1MB)');
        }

        // 2. Network awareness (WiFi vs Mobile)
        if (await _shouldDelayDueToNetwork(item)) {
          _updateStatus(SyncEngineStatus.idle); // Kutamiz
          break;
        }

        await _processItem(item);
        
        _successCount++;
        await _queueService.updateItemStatus(item, SyncStatus.done);
        await _queueService.removeItem(item); 
      } catch (e) {
        _failureCount++;
        await _handleError(item, e);
        // ... keyingi itemga o'tish (non-fatal bo'lsa)
      }
    }
  }

  bool _checkPayloadLimit(SyncItem item) {
    final size = jsonEncode(item.payload).length;
    return size <= 1024 * 1024; // 1MB
  }

  Future<bool> _shouldDelayDueToNetwork(SyncItem item) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isMobile = connectivity.contains(ConnectivityResult.mobile);
    final size = jsonEncode(item.payload).length;
    
    // Agar mobile data bo'lsa va payload > 100KB bo'lsa, WiFi kutish (misol uchun)
    if (isMobile && size > 100 * 1024) {
      debugPrint('Sync: Large payload ($size bytes) on mobile data. Waiting for WiFi...');
      return true;
    }
    return false;
  }

  Future<void> _processItem(SyncItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Firestore Reference aniqlash
    final docRef = _getDocRef(item, uid);
    
    // Conflict Detection: Remote holatni tekshiramiz
    if (item.operation != SyncOperation.delete) {
      final remoteDoc = await docRef.get();
      if (remoteDoc.exists) {
        final remoteData = remoteDoc.data() as Map<String, dynamic>;
        final remoteVersion = remoteData['version'] as int? ?? 0;
        final remoteRequestId = remoteData['lastRequestId'] as String?;

        // 1. Idempotency check: Agar allaqachon shu requestId bilan yozilgan bo'lsa
        if (remoteRequestId == item.requestId) {
          return; // Skip, allaqachon bajarilgan
        }

        // 2. Conflict check: Remote versiya biznikidan katta yoki teng bo'lsa
        // (Lekin requestId boshqa bo'lsa - demak boshqa qurilma o'zgartirgan)
        if (remoteVersion >= item.version) {
          await _moveToConflictQueue(item, remoteData);
          return; // To'xtatamiz, user hal qilishi kerak
        }
      }
    }

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
      
      // Exponential Backoff: 2^retryCount sekund kutish (max 1 soat)
      final backoffSeconds = min(pow(2, item.retryCount).toInt(), 3600);
      debugPrint('Sync: Retrying in $backoffSeconds seconds...');
      
      Future.delayed(Duration(seconds: backoffSeconds), () => run());
    }
  }

  Future<void> _moveToConflictQueue(SyncItem item, Map<String, dynamic> remoteData) async {
    _conflictCount++;
    await _conflictService.addConflict(SyncConflict(
      id: const Uuid().v4(),
      entityId: item.entityId,
      entityType: item.entityType,
      localData: item.payload,
      remoteData: remoteData,
      detectedAt: DateTime.now(),
    ));
    
    // Asosiy navbatdan olib tashlaymiz, toki user hal qilmaguncha sync bo'lmasin
    await _queueService.updateItemStatus(item, SyncStatus.done); // Mantiqan tugadi, lekin conflictga o'tdi
    await _queueService.removeItem(item);
  }

  void _updateStatus(SyncEngineStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
