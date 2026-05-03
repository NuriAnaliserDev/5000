import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/station.dart';
import '../models/audit_entry.dart';
import 'hive_db.dart';
import 'cloud_sync_service.dart';
import '../utils/geology_validator.dart';
import '../utils/device_id_helper.dart';
import '../core/error/app_error.dart';

class StationRepository extends ChangeNotifier {
  late final Box<Station> _box;
  final CloudSyncService _cloudSync;

  /// Har [notifyListeners] da oshadi — [Selector] bilan UI faqat
  /// ma'lumot o'zgarganda qayta quriladi.
  int _dataGeneration = 0;
  int get dataGeneration => _dataGeneration;

  StationRepository(this._cloudSync) {
    _box = Hive.box<Station>(HiveDb.stationsBox);
  }

  /// Versioning va meta ma'lumotlarni majburiy o'rnatish
  Future<Station> _stamp(Station station, {bool increment = false}) async {
    final deviceId = await DeviceIdHelper.getDeviceId();
    // updatedBy uchun currentUser ID kerak bo'lsa, uni repositoryga o'tkazish kerak
    // Hozircha mavjud authorName dan foydalanamiz yoki author parametrini kutamiz
    
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

  // Manually sync all local stations to the cloud
  Future<void> syncAllToCloud() async {
    await _cloudSync.triggerSync();
  }

  List<Station> get stations =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Station? getById(dynamic id) => _box.get(id);

  Future<int> addStation(Station station) async {
    final error = GeologyValidator.validateStation(station);
    if (error != null) {
      throw AppError(error, category: ErrorCategory.validation);
    }

    final finalStation = await _stamp(station); // Initial version is 1
    final id = await _box.add(finalStation);
    notifyListeners();
    _cloudSync.syncStation(id, finalStation); // Auto sync to cloud
    return id;
  }

  Future<void> updateStation(dynamic key, Station updated,
      {String? author}) async {
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

    final finalUpdated = await _stamp(tempUpdated, increment: true);

    await _box.put(key, finalUpdated);
    notifyListeners();
    _cloudSync.syncStation(key, finalUpdated); // Auto sync to cloud
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

  Future<void> deleteStation(dynamic key) async {
    final s = _box.get(key);
    if (s != null) {
      // Barcha rasmlarni o'chirish (yangi format)
      if (s.photoPaths != null) {
        for (var p in s.photoPaths!) {
          try {
            await _deleteFile(p);
          } catch (e) {
            debugPrint('Failed to delete photo file "$p": $e');
          }
        }
      } else if (s.photoPath != null) {
        // Legacy format — orqaga moslik uchun
        try {
          await _deleteFile(s.photoPath!);
        } catch (e) {
          debugPrint('Failed to delete legacy photo "${s.photoPath}": $e');
        }
      }
      if (s.audioPath != null) {
        try {
          await _deleteFile(s.audioPath!);
        } catch (e) {
          debugPrint('Failed to delete audio "${s.audioPath}": $e');
        }
      }
    }
    await _box.delete(key);
    notifyListeners();
    unawaited(
        _cloudSync.deleteStation(key)); // Remove from cloud (fon rejimida)
  }

  /// Joriy foydalanuvchining BARCHA lokal stansiyalarini o'chiradi.
  /// Cloud'dan ham o'chirish uchun [clearCloud] = true qiling.
  /// Ehtiyot bo'ling: bu operatsiya qaytarib bo'lmaydi.
  Future<void> clear({bool clearCloud = true}) async {
    for (var s in _box.values) {
      if (s.photoPaths != null) {
        for (var p in s.photoPaths!) {
          try {
            await _deleteFile(p);
          } catch (e) {
            debugPrint('Failed to clear photo file "$p": $e');
          }
        }
      } else if (s.photoPath != null) {
        try {
          await _deleteFile(s.photoPath!);
        } catch (e) {
          debugPrint('Failed to clear legacy photo "${s.photoPath}": $e');
        }
      }
      if (s.audioPath != null) {
        try {
          await _deleteFile(s.audioPath!);
        } catch (e) {
          debugPrint('Failed to clear audio "${s.audioPath}": $e');
        }
      }
    }
    await _box.clear();
    notifyListeners();
    if (clearCloud) {
      unawaited(_cloudSync.clearUserStations()); // Faqat UID-scoped o'chirish
    }
  }

  Future<void> _deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<void> renameProject(String oldName, String newName) async {
    for (final rawKey in _box.keys) {
      final key = rawKey is int ? rawKey : int.tryParse(rawKey.toString());
      if (key == null) continue;
      final s = _box.get(key);
      if (s != null && s.project == oldName) {
        final updated = s.copyWith(project: newName);
        await _box.put(key, updated);
        unawaited(_cloudSync.syncStation(key, updated));
      }
    }
    notifyListeners();
  }

  Future<void> deleteProject(String projectName) async {
    final keysToDelete = <int>[];
    for (final rawKey in _box.keys) {
      final key = rawKey is int ? rawKey : int.tryParse(rawKey.toString());
      if (key == null) continue;
      final s = _box.get(key);
      if (s != null && s.project == projectName) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await deleteStation(key);
    }
    notifyListeners();
  }
}
