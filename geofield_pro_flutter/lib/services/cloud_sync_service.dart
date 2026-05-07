import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/station.dart';
import '../utils/firebase_ready.dart';
import '../core/di/dependency_injection.dart';
import '../core/config/app_features.dart';
import '../core/diagnostics/log_channels.dart';
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
    if (!AppFeatures.enableCloudSync) {
      debugPrint(
        '${DiagLogChannel.sync.prefix} CloudSyncService muzlatilgan (AppFeatures.enableCloudSync=false).',
      );
      return;
    }
    if (_firestore == null) {
      debugPrint(
        '${DiagLogChannel.sync.prefix} Firebase yo‘q — sinxron o‘chiq.',
      );
      return;
    }
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          debugPrint(
            '${DiagLogChannel.sync.prefix} Internet bor — SyncProcessor.run',
          );
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
    if (!AppFeatures.enableCloudSync) return;
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
    if (!AppFeatures.enableCloudSync) return true;
    sl<SyncProcessor>().run();
    return true;
  }

  Future<bool> deleteStation(dynamic key) async {
    if (!AppFeatures.enableCloudSync) return true;
    sl<SyncProcessor>().run();
    return true;
  }
}
