import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/diagnostics/production_diagnostics.dart';
import '../core/error/error_logger.dart';

import '../models/geological_line.dart';
import '../models/map_structure_annotation.dart';
import '../models/measurement.dart';
import '../models/audit_entry.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import '../models/chat_message.dart';
import '../models/chat_group.dart';
import '../models/project.dart';
import '../models/sync_item.dart';
import '../models/sync_conflict.dart';
import '../models/ai_analysis_result.dart';
import 'security/encryption_manager.dart';

class HiveDb {
  static const stationsBox = 'stations';
  static const tracksBox = 'tracks';
  static const settingsBox = 'settings';
  static const syncStateBox = 'sync_state';
  static const chatMessagesBox = 'chat_messages';
  static const chatGroupsBox = 'chat_groups';
  static const linesBox = 'geological_lines';
  static const mapStructureBox = 'map_structure_annotations';
  static const projectsBox = 'projects';
  static const syncQueueBox = 'sync_queue';
  static const syncConflictsBox = 'sync_conflicts';
  static const aiCacheBox = 'ai_cache';
  static const aiTelemetryBox = 'ai_telemetry';

  static Future<void> init() async {
    await Hive.initFlutter();

    _registerAdapter(StationAdapter());
    _registerAdapter(TrackDataAdapter());
    _registerAdapter(ChatMessageAdapter());
    _registerAdapter(ChatGroupAdapter());
    _registerAdapter(GeologicalLineAdapter());
    _registerAdapter(MeasurementAdapter());
    _registerAdapter(AuditEntryAdapter());
    _registerAdapter(MapStructureAnnotationAdapter());
    _registerAdapter(ProjectAdapter());
    _registerAdapter(SyncItemAdapter());
    _registerAdapter(SyncStatusAdapter());
    _registerAdapter(SyncOperationAdapter());
    _registerAdapter(SyncConflictAdapter());
    _registerAdapter(AIAnalysisResultAdapter());

    final cipher = await EncryptionManager.cipher();

    await _openTypedMigrate<Station>(stationsBox, cipher);
    await _openTypedMigrate<TrackData>(tracksBox, cipher);
    await _openTypedMigrate<ChatMessage>(chatMessagesBox, cipher);
    await _openTypedMigrate<ChatGroup>(chatGroupsBox, cipher);
    await _openTypedMigrate<GeologicalLine>(linesBox, cipher);
    await _openTypedMigrate<MapStructureAnnotation>(mapStructureBox, cipher);
    await _openTypedMigrate<Project>(projectsBox, cipher);
    await _openTypedMigrate<SyncItem>(syncQueueBox, cipher);
    await _openTypedMigrate<SyncConflict>(syncConflictsBox, cipher);
    await _openTypedMigrate<AIAnalysisResult>(aiCacheBox, cipher);
    await _openDynamicMigrate(aiTelemetryBox, cipher);
    await _openDynamicMigrate(settingsBox, cipher);
    await _openDynamicMigrate(syncStateBox, cipher);
  }

  /// Eski ochiq Hive qutilarini AES-256 ga ko‘chiradi; yangi o‘rnatishlar darhol shifrlangan.
  static Future<Box<T>> _openTypedMigrate<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    final exists = await Hive.boxExists(name);
    if (!exists) {
      return Hive.openBox<T>(name, encryptionCipher: cipher);
    }
    try {
      final plain = await Hive.openBox<T>(name);
      final map = Map<dynamic, T>.from(plain.toMap());
      await plain.close();
      await Hive.deleteBoxFromDisk(name);
      final enc = await Hive.openBox<T>(name, encryptionCipher: cipher);
      for (final e in map.entries) {
        await enc.put(e.key, e.value);
      }
      if (kDebugMode) {
        debugPrint('HiveDb: migrated "$name" → encrypted (${map.length} keys)');
      }
      return enc;
    } catch (e, st) {
      ErrorLogger.record(
        e,
        st,
        customMessage: 'HiveDb _openTypedMigrate failed: $name',
      );
      unawaited(
        ProductionDiagnostics.storage(
          'hive_typed_recover',
          phase: name,
          data: {'error': e.toString()},
        ),
      );
      try {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      } catch (_) {}
      return Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }

  static Future<Box> _openDynamicMigrate(
    String name,
    HiveAesCipher cipher,
  ) async {
    final exists = await Hive.boxExists(name);
    if (!exists) {
      return Hive.openBox(name, encryptionCipher: cipher);
    }
    try {
      final plain = await Hive.openBox(name);
      final map = Map<dynamic, dynamic>.from(plain.toMap());
      await plain.close();
      await Hive.deleteBoxFromDisk(name);
      final enc = await Hive.openBox(name, encryptionCipher: cipher);
      for (final e in map.entries) {
        await enc.put(e.key, e.value);
      }
      if (kDebugMode) {
        debugPrint('HiveDb: migrated "$name" → encrypted (${map.length} keys)');
      }
      return enc;
    } catch (e, st) {
      ErrorLogger.record(
        e,
        st,
        customMessage: 'HiveDb _openDynamicMigrate failed: $name',
      );
      unawaited(
        ProductionDiagnostics.storage(
          'hive_dynamic_recover',
          phase: name,
          data: {'error': e.toString()},
        ),
      );
      try {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      } catch (_) {}
      return Hive.openBox(name, encryptionCipher: cipher);
    }
  }

  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
