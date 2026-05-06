import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../config/cloud_features.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import '../models/chat_message.dart';
import '../utils/firebase_ready.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_logger.dart';
import '../core/error/app_error.dart';
import '../core/security/access_control_service.dart';
import '../core/di/dependency_injection.dart';
import 'hive_db.dart';
import 'sync/sync_processor.dart';

class CloudSyncService extends ChangeNotifier {
  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  final bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? get _currentUserId {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void init() {
    if (_firestore == null) {
      debugPrint('CloudSyncService: Firebase yo‘q — sinxron o‘chiq.');
      return;
    }
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          debugPrint('Haqiqiy internet aniqlandi: SyncProcessor run...');
          sl<SyncProcessor>().run();
        }
      }
    });

    Connectivity().checkConnectivity().then((results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          sl<SyncProcessor>().run();
        }
      }
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          sl<SyncProcessor>().run();
        }
      }
    });
  }

  Future<bool> hasRealInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3), onTimeout: () => []);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Legacy trigger support
  Future<void> triggerSync() async {
    if (await hasRealInternet()) {
      sl<SyncProcessor>().run();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // Legacy individual sync methods (will be removed as other repos migrate)
  // For now, they can stay or be redirected to queue if needed.
  // But since we are enforcing Write Enforcement, they should ideally throw.

  Future<bool> syncStation(dynamic key, Station station) async {
    // Redirection to run the processor (which will find the item in the queue)
    // Actually, StationRepository already adds it to the queue.
    sl<SyncProcessor>().run();
    return true;
  }

  Future<bool> deleteStation(dynamic key) async {
    sl<SyncProcessor>().run();
    return true;
  }
}
