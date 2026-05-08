import 'dart:convert';

import '../domain/observation_state_derivation.dart';
import '../models/field_trust_meta.dart';
import '../models/observation_pipeline_types.dart';
import '../models/station.dart';

/// Observation lifecycle uchun yagona servis qatlami (UI o‘zgartirilmaydi).
///
/// Derivation markazi: [ObservationStateDerivation.deriveObservationState].
abstract final class ObservationPipelineService {
  /// Eksport / konsumentlar: JSON’ni qayta talqin qilmasdan decode (kategoriya qayta hisoblanadi).
  static FieldTrustMeta? canonicalFieldTrustMeta(Station station) {
    return FieldTrustMeta.decode(station.fieldTrustMetaJson);
  }

  /// `createObservation` — capture’dan keyin meta biriktirish (nom konventsiyasi).
  static Station createObservation(
    Station station, {
    required FieldTrustMeta meta,
  }) =>
      attachCaptureMeta(station, meta: meta);

  /// `updateObservation` — qo‘lda tahrir trust (repository bilan bir xil).
  static Station updateObservation(Station updated) =>
      updateObservationTrustForManualEdit(updated);

  /// Capture’dan keyin — [FieldTrustMeta.forCapture] pipeline orqali.
  static Station attachCaptureMeta(
    Station station, {
    required FieldTrustMeta meta,
  }) {
    return station.copyWith(fieldTrustMetaJson: meta.encode());
  }

  /// Qo‘lda tahrir — mavjud degrade siyosati + provenance.
  static Station updateObservationTrustForManualEdit(Station updated) {
    final meta = FieldTrustMeta.decode(updated.fieldTrustMetaJson);
    if (meta == null) return updated;
    final next = FieldTrustMeta.degradedAfterManualEdit(meta);
    return updated.copyWith(fieldTrustMetaJson: next.encode());
  }

  /// Import: agregat kategoriyasini buzmaymiz, faqat provenance yoziladi.
  static Station importObservation(Station imported) {
    final meta = FieldTrustMeta.decode(imported.fieldTrustMetaJson);
    if (meta == null) return imported;
    final merged = _withProvenance(
      meta,
      const ObservationProvenance(source: ObservationMutationSource.fromImport),
    );
    return imported.copyWith(fieldTrustMetaJson: merged.encode());
  }

  static Station mergeObservationFromSync(Station merged) {
    final meta = FieldTrustMeta.decode(merged.fieldTrustMetaJson);
    if (meta == null) return merged;
    final m = _withProvenance(
      meta,
      const ObservationProvenance(source: ObservationMutationSource.sync_merge),
    );
    return merged.copyWith(fieldTrustMetaJson: m.encode());
  }

  /// `mergeObservation` — bulut bilan sinxron birikish (provenance).
  static Station mergeObservation(Station merged) =>
      mergeObservationFromSync(merged);

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
    );
  }

  static ObservationDerivationResult deriveObservationState(
    ObservationRawFacts facts,
  ) {
    return ObservationStateDerivation.deriveObservationState(facts);
  }

  /// Inflight JSON (splash) — recovery lifecycle kirish nuqtasi.
  static ObservationRecoveryContext recoverObservation(String? inflightJson) {
    if (inflightJson == null || inflightJson.isEmpty) {
      return const ObservationRecoveryContext();
    }
    return recoveryContextFromInflightJson(inflightJson);
  }

  /// Inflight JSON (splash) → struktural kontekst.
  static ObservationRecoveryContext recoveryContextFromInflightJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ObservationRecoveryContext.fromInflightMap(m);
    } catch (_) {
      return const ObservationRecoveryContext();
    }
  }
}
