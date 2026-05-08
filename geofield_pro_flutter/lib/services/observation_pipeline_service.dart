import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../domain/observation_state_derivation.dart';
import '../models/field_trust_meta.dart';
import '../models/observation_mutation_event.dart';
import '../models/observation_pipeline_types.dart';
import '../models/station.dart';
import 'observation_mutation_journal.dart';
import 'observation_pipeline_gate.dart';

/// Observation lifecycle — kanonik yo‘l. [FieldTrustMeta.forCapture] / tahrir faqat gate ichida.
///
/// Derivation markazi: [ObservationStateDerivation.deriveObservationState].
abstract final class ObservationPipelineService {
  static FieldTrustMeta? canonicalFieldTrustMeta(Station station) {
    return FieldTrustMeta.decode(station.fieldTrustMetaJson);
  }

  /// Capture trust — **smart_camera** va testlarda shu metod ishlatilsin.
  static FieldTrustMeta buildCaptureTrustMeta({
    Position? pos,
    String? locationSource,
    required int captureWallClockMs,
    required String fieldSessionId,
    required String captureId,
    required bool networkConnected,
    int? batteryPct,
    int? lastCaptureEpochMs,
    String? imageSha256,
    int? imageSizeBytes,
    String? duplicateSessionImageHashMatchCaptureId,
    String? lastSuccessImageSha256,
    int? lastSuccessCaptureWallMs,
  }) {
    return ObservationPipelineGate.run(
      () => FieldTrustMeta.forCapture(
        pos: pos,
        locationSource: locationSource,
        captureWallClockMs: captureWallClockMs,
        fieldSessionId: fieldSessionId,
        captureId: captureId,
        networkConnected: networkConnected,
        batteryPct: batteryPct,
        lastCaptureEpochMs: lastCaptureEpochMs,
        imageSha256: imageSha256,
        imageSizeBytes: imageSizeBytes,
        duplicateSessionImageHashMatchCaptureId:
            duplicateSessionImageHashMatchCaptureId,
        lastSuccessImageSha256: lastSuccessImageSha256,
        lastSuccessCaptureWallMs: lastSuccessCaptureWallMs,
      ),
    );
  }

  static Station createObservation(
    Station station, {
    required FieldTrustMeta meta,
  }) =>
      attachCaptureMeta(station, meta: meta);

  static Station updateObservation(Station updated) =>
      updateObservationTrustForManualEdit(updated);

  static Station attachCaptureMeta(
    Station station, {
    required FieldTrustMeta meta,
  }) {
    return ObservationPipelineGate.run(() {
      ObservationMutationJournal.append(
        ObservationMutationEvent(
          observationId: meta.captureId,
          timestampMsUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          mutationSource: ObservationMutationSource.capture,
          changedFields: const ['fieldTrustMetaJson'],
          previousCategory: null,
          newCategory: meta.category,
          previousWarnings: const [],
          newWarnings: meta.warnings,
          reasonHint: 'attach_capture_meta',
        ),
      );
      return station.copyWith(fieldTrustMetaJson: meta.encode());
    });
  }

  static Station updateObservationTrustForManualEdit(Station updated) {
    return ObservationPipelineGate.run(() {
      final meta = FieldTrustMeta.decode(updated.fieldTrustMetaJson);
      if (meta == null) return updated;
      final next = FieldTrustMeta.degradedAfterManualEdit(meta);
      ObservationMutationJournal.append(
        ObservationMutationEvent(
          observationId: meta.captureId,
          timestampMsUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          mutationSource: ObservationMutationSource.manual_edit,
          changedFields: const ['fieldTrustMetaJson'],
          previousCategory: meta.category,
          newCategory: next.category,
          previousWarnings: meta.warnings,
          newWarnings: next.warnings,
          reasonHint: 'manual_sensitive_fields',
        ),
      );
      return updated.copyWith(fieldTrustMetaJson: next.encode());
    });
  }

  static Station importObservation(Station imported) {
    return ObservationPipelineGate.run(() {
      final meta = FieldTrustMeta.decode(imported.fieldTrustMetaJson);
      if (meta == null) return imported;
      final merged = _withProvenance(
        meta,
        const ObservationProvenance(source: ObservationMutationSource.fromImport),
      );
      ObservationMutationJournal.append(
        ObservationMutationEvent(
          observationId: meta.captureId,
          timestampMsUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          mutationSource: ObservationMutationSource.fromImport,
          changedFields: const ['provenance'],
          previousCategory: meta.category,
          newCategory: merged.category,
          previousWarnings: meta.warnings,
          newWarnings: merged.warnings,
          reasonHint: 'import_provenance_stamp',
        ),
      );
      return imported.copyWith(fieldTrustMetaJson: merged.encode());
    });
  }

  static Station mergeObservationFromSync(Station merged) {
    return ObservationPipelineGate.run(() {
      final meta = FieldTrustMeta.decode(merged.fieldTrustMetaJson);
      if (meta == null) return merged;
      final m = _withProvenance(
        meta,
        const ObservationProvenance(source: ObservationMutationSource.sync_merge),
      );
      ObservationMutationJournal.append(
        ObservationMutationEvent(
          observationId: meta.captureId,
          timestampMsUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          mutationSource: ObservationMutationSource.sync_merge,
          changedFields: const ['provenance'],
          previousCategory: meta.category,
          newCategory: m.category,
          previousWarnings: meta.warnings,
          newWarnings: m.warnings,
          reasonHint: 'sync_merge_stamp',
        ),
      );
      return merged.copyWith(fieldTrustMetaJson: m.encode());
    });
  }

  static Station mergeObservation(Station merged) =>
      mergeObservationFromSync(merged);

  /// Persist qilingan stansiya + meta asosida qayta derivation (GPS to‘liq replay yo‘q).
  static FieldTrustMeta? rederiveObservation(Station station) {
    return ObservationPipelineGate.run(() {
      final prior = FieldTrustMeta.decode(station.fieldTrustMetaJson);
      if (prior == null) return null;

      final wall =
          prior.captureEpochMs ?? station.date.millisecondsSinceEpoch;

      PositionLike? pos;
      if (prior.coordinateTrusted &&
          !(station.lat == 0 && station.lng == 0) &&
          prior.locationSource != FieldTrustMeta.sourceAbsent) {
        final fix = prior.gpsFixUtcIso != null
            ? DateTime.tryParse(prior.gpsFixUtcIso!)
            : null;
        pos = PositionLike(
          latitude: station.lat,
          longitude: station.lng,
          altitude: station.altitude,
          accuracy: station.accuracy ?? 999,
          timestamp: fix ?? station.date,
          isMocked: prior.gpsMockSuspected,
          altitudeAccuracy: prior.altitudeAvailable ? 4.0 : 0,
        );
      }

      final facts = ObservationRawFacts(
        position: pos,
        locationSourceOverride: pos == null ? null : prior.locationSource,
        captureWallClockMs: wall,
        fieldSessionId: prior.fieldSessionId,
        captureId: prior.captureId,
        networkConnected: prior.networkConnected,
        batteryPct: prior.batteryPct,
        imageSha256: prior.imageSha256,
        imageSizeBytes: prior.imageSizeBytes,
        duplicateSessionHashMatchCaptureId:
            prior.observationDuplicate?.canonicalObservationId,
        provenance:
            const ObservationProvenance(source: ObservationMutationSource.migration),
      );

      final d = ObservationStateDerivation.deriveObservationState(
        facts,
        derivedAtUtc:
            DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true),
      );

      final dup = d.duplicateInfo.isEmpty
          ? prior.observationDuplicate
          : d.duplicateInfo;

      return FieldTrustMeta(
        schemaVersion: '3',
        locationSource: prior.locationSource,
        coordinateTrusted: prior.coordinateTrusted,
        gpsFixStale: prior.gpsFixStale,
        gpsMockSuspected: prior.gpsMockSuspected,
        gpsFixUtcIso: prior.gpsFixUtcIso,
        horizontalAccuracyM: prior.horizontalAccuracyM,
        captureEpochMs: prior.captureEpochMs,
        captureWallClockUtcIso: prior.captureWallClockUtcIso,
        fieldSessionId: prior.fieldSessionId,
        captureId: prior.captureId,
        networkConnected: prior.networkConnected,
        batteryPct: prior.batteryPct,
        altitudeAvailable: prior.altitudeAvailable,
        trustScore: d.trustScore,
        warnings: d.normalizedWarnings,
        category: d.category,
        imageSha256: prior.imageSha256,
        imageSizeBytes: prior.imageSizeBytes,
        observationDuplicate: dup,
        lastMutationProvenance: d.provenance,
        observationIntegrity: prior.observationIntegrity ?? d.integrityInfo,
        storedDerivationVersion:
            ObservationDerivationResult.derivationLogicVersion,
      );
    });
  }

  static FieldTrustMeta _withProvenance(
    FieldTrustMeta meta,
    ObservationProvenance addition,
  ) {
    return FieldTrustMeta(
      schemaVersion: meta.schemaVersion,
      locationSource: meta.locationSource,
      coordinateTrusted: meta.coordinateTrusted,
      gpsFixStale: meta.gpsFixStale,
      gpsMockSuspected: meta.gpsMockSuspected,
      gpsFixUtcIso: meta.gpsFixUtcIso,
      horizontalAccuracyM: meta.horizontalAccuracyM,
      captureEpochMs: meta.captureEpochMs,
      captureWallClockUtcIso: meta.captureWallClockUtcIso,
      fieldSessionId: meta.fieldSessionId,
      captureId: meta.captureId,
      networkConnected: meta.networkConnected,
      batteryPct: meta.batteryPct,
      altitudeAvailable: meta.altitudeAvailable,
      trustScore: meta.trustScore,
      warnings: meta.warnings,
      category: meta.category,
      imageSha256: meta.imageSha256,
      imageSizeBytes: meta.imageSizeBytes,
      observationDuplicate: meta.observationDuplicate,
      lastMutationProvenance: addition,
      observationIntegrity: meta.observationIntegrity,
      storedDerivationVersion: meta.storedDerivationVersion,
    );
  }

  static ObservationDerivationResult deriveObservationState(
    ObservationRawFacts facts, {
    DateTime? derivedAtUtc,
  }) {
    return ObservationStateDerivation.deriveObservationState(
      facts,
      derivedAtUtc: derivedAtUtc,
    );
  }

  static ObservationRecoveryContext recoverObservation(String? inflightJson) {
    if (inflightJson == null || inflightJson.isEmpty) {
      return const ObservationRecoveryContext();
    }
    return recoveryContextFromInflightJson(inflightJson);
  }

  static ObservationRecoveryContext recoveryContextFromInflightJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ObservationRecoveryContext.fromInflightMap(m);
    } catch (_) {
      return const ObservationRecoveryContext();
    }
  }
}
