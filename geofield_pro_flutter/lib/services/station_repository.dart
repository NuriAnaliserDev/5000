import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../core/diagnostics/production_diagnostics.dart';
import '../core/error/app_error.dart';
import '../models/field_trust_meta.dart';
import '../models/station.dart';
import '../models/audit_entry.dart';
import '../models/sync_item.dart';
import 'hive_db.dart';
import 'cloud_sync_service.dart';
import 'sync/sync_queue_service.dart';
import '../utils/geology_validator.dart';
import '../utils/device_id_helper.dart';
import '../services/observation_pipeline_service.dart';

class StationRepository extends ChangeNotifier {
  late final Box<Station> _box;
  final CloudSyncService _cloudSync;
  final SyncQueueService _syncQueue;

  /// Har [notifyListeners] da oshadi — [Selector] bilan UI faqat
  /// ma'lumot o'zgarganda qayta quriladi.
  int _dataGeneration = 0;
  int get dataGeneration => _dataGeneration;

  final _lock = Lock();

  StationRepository(this._cloudSync, this._syncQueue) {
    _box = Hive.box<Station>(HiveDb.stationsBox);
  }

  /// Versioning va meta ma'lumotlarni majburiy o'rnatish
  Future<Station> _stamp(Station station, {bool increment = false}) async {
    final deviceId = await DeviceIdHelper.getDeviceId();

    return station.copyWith(
      version: increment ? (station.version + 1) : station.version,
      updatedAt: DateTime.now(),
      updatedByDeviceId: deviceId,
    );
  }

  @override
  void notifyListeners() {
    _dataGeneration++;
    super.notifyListeners();
  }

  // Manually sync all local stations to the cloud (Legacy trigger)
  Future<void> syncAllToCloud() async {
    await _cloudSync.triggerSync();
  }

  List<Station> get stations => _box.values.where((s) => !s.isDeleted).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Station? getById(dynamic id) => _box.get(id);

  /// Sessiya ichidagi bir xil surat tarkibi (SHA-256) — mazmun bo‘yicha takror.
  String? findDuplicateImageHashInSession({
    required String sessionId,
    required String imageSha256,
  }) {
    if (imageSha256.isEmpty) return null;
    for (final s in _box.values) {
      if (s.isDeleted) continue;
      final meta = FieldTrustMeta.decode(s.fieldTrustMetaJson);
      if (meta == null) continue;
      if (meta.fieldSessionId != sessionId) continue;
      if (meta.imageSha256 == imageSha256) {
        return meta.captureId;
      }
    }
    return null;
  }

  Future<int> addStation(Station station,
      {UpdateSource source = UpdateSource.local}) async {
    return await _lock.synchronized(() async {
      final error = GeologyValidator.validateStation(station);
      if (error != null) {
        throw AppError(error, category: ErrorCategory.validation);
      }

      try {
        final finalStation = await _stamp(station);
        final id = await _box.add(finalStation);

        if (source == UpdateSource.local) {
          await _syncQueue.addItem(SyncItem(
            id: const Uuid().v4(),
            entityType: 'station',
            entityId: id.toString(),
            payload: finalStation.toMap(),
            version: finalStation.version,
            operation: SyncOperation.create,
            requestId: const Uuid().v4(),
            sequence: _syncQueue.getNextSequence(),
            createdAt: DateTime.now(),
          ));
        }

        notifyListeners();
        return id;
      } catch (e, st) {
        unawaited(
          ProductionDiagnostics.storage(
            'station_persist_failed',
            data: {'error': e.toString()},
          ),
        );
        if (kDebugMode) {
          debugPrintStack(stackTrace: st);
        }
        rethrow;
      }
    });
  }

  Future<void> updateStation(dynamic key, Station updated,
      {String? author,
      UpdateSource source = UpdateSource.local,
      String? customRequestId}) async {
    await _lock.synchronized(() async {
      final error = GeologyValidator.validateStation(updated);
      if (error != null) {
        throw AppError(error, category: ErrorCategory.validation);
      }

      final oldStation = _box.get(key);
      Station tempUpdated = updated;
      if (oldStation != null && author != null) {
        final entries = _generateAuditEntries(oldStation, updated, author);
        if (entries.isNotEmpty) {
          tempUpdated = updated.copyWith(
            history: [...(updated.history ?? []), ...entries],
            updatedBy: author,
          );
        }
      }

      var finalUpdated =
          await _stamp(tempUpdated, increment: source == UpdateSource.local);
      if (oldStation != null && source == UpdateSource.local) {
        if (_trustSensitiveFieldsChanged(oldStation, finalUpdated)) {
          finalUpdated =
              ObservationPipelineService.updateObservationTrustForManualEdit(
                  finalUpdated);
        }
      }

      await _box.put(key, finalUpdated);

      if (source == UpdateSource.local) {
        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'station',
          entityId: key.toString(),
          payload: finalUpdated.toMap(),
          version: finalUpdated.version,
          operation: SyncOperation.update,
          requestId: customRequestId ?? const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      }

      notifyListeners();
    });
  }

  Future<void> deleteStation(dynamic key,
      {UpdateSource source = UpdateSource.local}) async {
    return await _lock.synchronized(() async {
      final station = _box.get(key);
      if (station == null || station.isDeleted) return;

      if (source == UpdateSource.local) {
        // Soft delete locally
        final deletedStation = station.copyWith(isDeleted: true);
        await _box.put(key, deletedStation);

        await _syncQueue.addItem(SyncItem(
          id: const Uuid().v4(),
          entityType: 'station',
          entityId: key.toString(),
          payload: {},
          version: station.version,
          operation: SyncOperation.delete,
          requestId: const Uuid().v4(),
          sequence: _syncQueue.getNextSequence(),
          createdAt: DateTime.now(),
        ));
      } else {
        // Hard delete if it's a remote instruction (or we can keep it as soft delete if we want)
        await _box.delete(key);
      }

      notifyListeners();
    });
  }

  bool _trustSensitiveFieldsChanged(Station a, Station b) {
    if (a.lat != b.lat || a.lng != b.lng || a.altitude != b.altitude) {
      return true;
    }
    if (a.date != b.date) return true;
    final aa = a.accuracy;
    final ba = b.accuracy;
    if (aa != ba) {
      if (aa == null || ba == null) return true;
      if ((aa - ba).abs() > 1e-9) return true;
    }
    if (a.photoPath != b.photoPath) return true;
    final ap = a.photoPaths ?? const <String>[];
    final bp = b.photoPaths ?? const <String>[];
    if (ap.length != bp.length) return true;
    for (var i = 0; i < ap.length; i++) {
      if (ap[i] != bp[i]) return true;
    }
    return false;
  }

  List<AuditEntry> _generateAuditEntries(
      Station oldS, Station newS, String author) {
    final entries = <AuditEntry>[];
    final now = DateTime.now();

    void checkField(String name, dynamic oldV, dynamic newV) {
      if (oldV != newV) {
        entries.add(AuditEntry(
          timestamp: now,
          author: author,
          fieldName: name,
          oldValue: oldV?.toString() ?? 'empty',
          newValue: newV?.toString() ?? 'empty',
        ));
      }
    }

    checkField('name', oldS.name, newS.name);
    checkField('rockType', oldS.rockType, newS.rockType);
    checkField('structure', oldS.structure, newS.structure);
    checkField('description', oldS.description, newS.description);
    checkField('strike', oldS.strike, newS.strike);
    checkField('dip', oldS.dip, newS.dip);
    checkField('azimuth', oldS.azimuth, newS.azimuth);
    checkField('sampleId', oldS.sampleId, newS.sampleId);

    return entries;
  }

  /// Joriy foydalanuvchining BARCHA lokal stansiyalarini o'chiradi.
  Future<void> clear({bool clearCloud = true}) async {
    await _lock.synchronized(() async {
      for (var s in _box.values) {
        if (s.photoPaths != null) {
          for (var p in s.photoPaths!) {
            await _deleteFile(p);
          }
        } else if (s.photoPath != null) {
          await _deleteFile(s.photoPath!);
        }
        if (s.audioPath != null) {
          await _deleteFile(s.audioPath!);
        }

        if (clearCloud) {
          // Add to queue as delete
          final key = s.key;
          if (key != null) {
            await _syncQueue.addItem(SyncItem(
              id: const Uuid().v4(),
              entityType: 'station',
              entityId: key.toString(),
              payload: {},
              version: s.version,
              operation: SyncOperation.delete,
              requestId: const Uuid().v4(),
              sequence: _syncQueue.getNextSequence(),
              createdAt: DateTime.now(),
            ));
          }
        }
      }
      await _box.clear();
      notifyListeners();
    });
  }

  Future<void> _deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      debugPrint('File delete error: $e');
    }
  }

  Future<void> renameProject(String oldName, String newName) async {
    await _lock.synchronized(() async {
      for (final rawKey in _box.keys) {
        final key = rawKey;
        final s = _box.get(key);
        if (s != null && s.project == oldName) {
          final updated = s.copyWith(project: newName);
          await updateStation(key, updated);
        }
      }
      notifyListeners();
    });
  }

  Future<void> deleteProject(String projectName) async {
    await _lock.synchronized(() async {
      final List<dynamic> keysToDelete = [];
      for (final rawKey in _box.keys) {
        final s = _box.get(rawKey);
        if (s != null && s.project == projectName && !s.isDeleted) {
          keysToDelete.add(rawKey);
        }
      }

      for (final key in keysToDelete) {
        final station = _box.get(key);
        if (station != null) {
          // Soft delete locally (no separate sync item per station to avoid noise)
          await _box.put(key, station.copyWith(isDeleted: true));
        }
      }

      // Single bulk delete item for the whole project
      await _syncQueue.addItem(SyncItem(
        id: const Uuid().v4(),
        entityType: 'project_stations',
        entityId: projectName,
        payload: {'projectName': projectName},
        version: 0, // Bulk ops versioning handled by sequence/timestamp
        operation: SyncOperation.delete,
        requestId: const Uuid().v4(),
        sequence: _syncQueue.getNextSequence(),
        createdAt: DateTime.now(),
      ));

      notifyListeners();
    });
  }
}
