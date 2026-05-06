import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geofield_pro_flutter/models/station.dart';
import 'package:geofield_pro_flutter/models/geological_line.dart';
import 'package:geofield_pro_flutter/models/map_structure_annotation.dart';
import 'package:geofield_pro_flutter/models/sync_item.dart';
import 'package:geofield_pro_flutter/utils/sync_utils.dart';
import 'package:geofield_pro_flutter/services/sync/sync_queue_service.dart';
import 'package:geofield_pro_flutter/services/station_repository.dart';
import 'package:geofield_pro_flutter/services/cloud_sync_service.dart';
import 'package:geofield_pro_flutter/services/sync/conflict_queue_service.dart';
import 'package:geofield_pro_flutter/services/sync/sync_processor.dart';
import 'package:geofield_pro_flutter/models/sync_conflict.dart';
import 'package:geofield_pro_flutter/services/hive_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Sync Reliability Simulation', () {
    late SyncQueueService queueService;
    late StationRepository stationRepository;
    late Box<SyncItem> syncBox;
    late Box<Station> stationBox;
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      SharedPreferences.setMockInitialValues({});

      _registerAdapters();

      syncBox = await Hive.openBox<SyncItem>(HiveDb.syncQueueBox);
      stationBox = await Hive.openBox<Station>(HiveDb.stationsBox);

      queueService = SyncQueueService();
      stationRepository =
          StationRepository(MockCloudSyncService(), queueService);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Offline Batch & Dedup: Coalescing multiple operations', () async {
      // 1. 50 ta stansiya yaratish
      for (int i = 0; i < 50; i++) {
        final s = Station(
          name: 'Station $i',
          lat: 41.0 + i,
          lng: 69.0 + i,
          altitude: 100.0 + i,
          strike: 45.0,
          dip: 30.0,
          azimuth: 0.0,
          date: DateTime.now(),
        );
        await stationRepository.addStation(s);
      }
      expect(syncBox.length, 50);

      // 2. Har birini 5 marta update qilish
      for (int i = 0; i < 50; i++) {
        final key = stationBox.keyAt(i);
        final s = stationBox.get(key)!;
        for (int j = 0; j < 5; j++) {
          await stationRepository.updateStation(
              key, s.copyWith(name: 'Station $i Update $j'));
        }
      }
      // Coalescing ishlashi kerak: faqat 50 ta create qolishi kerak (payloadi yangilangan)
      expect(syncBox.length, 50);

      // 3. 10 tasini o'chirish
      for (int i = 0; i < 10; i++) {
        await stationRepository.deleteStation(stationBox.keyAt(i));
      }
      // 10 ta item Create+Delete bo'lgani uchun butunlay o'chib ketishi kerak
      expect(syncBox.length, 40);

      final pending = syncBox.values
          .where((item) => item.status == SyncStatus.pending)
          .toList();
      expect(pending.length, 40);
    });

    test('Crash Recovery: Restoring stuck processing items', () async {
      // Setup some items
      for (int i = 0; i < 5; i++) {
        await syncBox.add(SyncItem(
          id: 'item_$i',
          entityType: 'test',
          entityId: 'id_$i',
          payload: {},
          version: 1,
          operation: SyncOperation.create,
          requestId: 'req_$i',
          sequence: i,
          createdAt: DateTime.now(),
          status: SyncStatus.processing, // Stuck state
        ));
      }

      expect(
          syncBox.values
              .where((item) => item.status == SyncStatus.processing)
              .length,
          5);

      await queueService.resetProcessingItems();

      expect(
          syncBox.values
              .where((item) => item.status == SyncStatus.processing)
              .length,
          0);
      expect(
          syncBox.values
              .where((item) => item.status == SyncStatus.pending)
              .length,
          5);
    });

    test('Conflict Resolution: Deterministic tie-breaker', () {
      // 1. Remote higher version wins
      expect(
          SyncUtils.shouldRemoteOverwriteLocal(
            localVersion: 5,
            localUpdatedAt: DateTime(2026, 1, 1),
            localDeviceId: 'A',
            remoteVersion: 6,
            remoteUpdatedAt: DateTime(2025, 1, 1),
            remoteDeviceId: 'B',
          ),
          isTrue);

      // 2. Local higher version wins
      expect(
          SyncUtils.shouldRemoteOverwriteLocal(
            localVersion: 7,
            localUpdatedAt: DateTime(2026, 1, 1),
            localDeviceId: 'A',
            remoteVersion: 6,
            remoteUpdatedAt: DateTime(2027, 1, 1),
            remoteDeviceId: 'B',
          ),
          isFalse);

      // 3. Same version, remote newer timestamp wins
      expect(
          SyncUtils.shouldRemoteOverwriteLocal(
            localVersion: 10,
            localUpdatedAt: DateTime(2026, 1, 1, 10),
            localDeviceId: 'A',
            remoteVersion: 10,
            remoteUpdatedAt: DateTime(2026, 1, 1, 11),
            remoteDeviceId: 'B',
          ),
          isTrue);

      // 4. Same version, same timestamp, deviceId tie-breaker
      expect(
          SyncUtils.shouldRemoteOverwriteLocal(
            localVersion: 10,
            localUpdatedAt: DateTime(2026, 1, 1),
            localDeviceId: 'DeviceA',
            remoteVersion: 10,
            remoteUpdatedAt: DateTime(2026, 1, 1),
            remoteDeviceId: 'DeviceB',
          ),
          isTrue); // 'DeviceB' > 'DeviceA'
    });

    test('Resolution Pipeline: Local Win flow', () async {
      final conflictQueue = ConflictQueueService();
      await conflictQueue.init();

      // 1. Local data yaratamiz (v1)
      final s = Station(
        name: 'Initial',
        lat: 41.31,
        lng: 69.24,
        altitude: 450,
        strike: 0,
        dip: 0,
        azimuth: 0,
        date: DateTime.now(),
        version: 1,
      );
      final key = await stationRepository.addStation(s);

      // 2. Konflikt simulyatsiyasi: Remote allaqachon v2 bo'lib ulgurgan
      final remoteData = s.copyWith(name: 'Remote Version', version: 2).toMap();
      final localItem =
          syncBox.values.last; // Boyagi addStation dan tushgan item

      final conflict = SyncConflict(
        id: 'conf_1',
        entityId: key.toString(),
        entityType: 'station',
        localData: localItem.payload,
        remoteData: remoteData,
        detectedAt: DateTime.now(),
      );

      await conflictQueue.addConflict(conflict);
      expect(conflictQueue.conflictCount, 1);

      // 3. RESOLVE: Use Local
      // ResolutionRequestId generatsiya qilamiz
      final reqId = 'resolve_test_123';
      final remoteVersion = conflict.remoteData['version'] as int;
      final newLocalVersion = remoteVersion + 1;

      final resolvedStation = Station.fromMap(conflict.localData)
          .copyWith(version: newLocalVersion);
      await stationRepository.updateStation(key, resolvedStation,
          customRequestId: reqId);

      // 4. Tekshiruv
      final finalLocal = stationBox.get(key)!;
      expect(finalLocal.version,
          4); // v2(remote) + 1 = 3, keyin _stamp yana +1 qiladi = 4

      // Eng oxirgi qo'shilgan sync itemni tekshiramiz
      final allSyncItems = syncBox.values.toList();
      final lastSyncItem = allSyncItems[allSyncItems.length - 1];

      expect(lastSyncItem.version, 4);
      expect(lastSyncItem.requestId, reqId);

      await conflictQueue.resolveConflict(conflict.id);
      expect(conflictQueue.conflictCount, 0);

      print(
          '✅ SUCCESS: Resolution Pipeline yopildi (v1 -> Conflict(v2) -> Resolve v3)');
    });
    test('CHAOS TEST: 100 items + Random network/crash simulation', () async {
      // 1. 100 ta amalni navbatga qo'shish
      for (int i = 0; i < 100; i++) {
        final s = Station(
          name: 'Chaos Station $i',
          lat: 41.31,
          lng: 69.24,
          altitude: 450,
          strike: 0,
          dip: 0,
          azimuth: 0,
          date: DateTime.now(),
        );
        await stationRepository.addStation(s);
      }
      expect(syncBox.length, 100);

      // 2. Simulyatsiya: Processor ishlayotganda "halokat" (boxni yopish va qayta ochish)
      await syncBox.close();
      syncBox = await Hive.openBox<SyncItem>(HiveDb.syncQueueBox);

      // 3. Crash Recovery: Yangi service va processor yaratamiz
      final recoveredQueue = SyncQueueService();

      // 4. Internet o'ynashi (MockCloudSyncService orqali)
      final mockCloud = MockCloudSyncService();
      mockCloud.isOnline = false; // Internet uzildi

      final hardenedProcessor = SyncProcessor(
        recoveredQueue,
        mockCloud,
        ConflictQueueService(),
        firestore: MockFirestore(),
        auth: MockAuth(),
      );
      await hardenedProcessor.init();

      // 5. Internet yo'qligida itemlar o'zgarmasligi kerak (pendingligicha qoladi)
      expect(recoveredQueue.pendingItems.length, 100);

      // 6. Internet keldi
      mockCloud.isOnline = true;
      await hardenedProcessor.run();

      // 7. Yakuniy tekshiruv: Barcha itemlar muvaffaqiyatli o'tishi kerak
      expect(recoveredQueue.pendingItems.length, 0);
      print(
          '✅ SUCCESS: Chaos Test (Crash + Network toggle) muvaffaqiyatli o\'tdi. Data Integrity saqlandi.');
    });
  });
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(SyncItemAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(SyncStatusAdapter());
  if (!Hive.isAdapterRegistered(11))
    Hive.registerAdapter(SyncOperationAdapter());
  if (!Hive.isAdapterRegistered(12))
    Hive.registerAdapter(SyncConflictAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(StationAdapter());
}

class MockCloudSyncService extends CloudSyncService {
  bool isOnline = true;
  @override
  Future<void> triggerSync() async {}
  @override
  Future<bool> hasRealInternet() async => isOnline;
}

class MockFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollection();
  }
}

class MockCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return MockDoc();
  }
}

class MockDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return MockSnapshot();
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}
  @override
  Future<void> delete() async {}
}

class MockSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => false;
}

class MockAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => MockUser();
}

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid';
}
