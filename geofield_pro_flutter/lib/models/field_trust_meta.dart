import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../core/diagnostics/app_timeouts.dart';
import '../domain/observation_state_derivation.dart';
import 'observation_pipeline_types.dart';
import 'observation_warn_codes.dart';
import 'field_trust_category.dart';

/// Dalada yozilgan yozuv uchun ishonch metadatasi.
///
/// **[FieldTrustCategory] — kategoriya = yagona ommaviy semantik holat.**
/// **[trustScore] — faqat ichki evristik; category bilan tenglashtirilmasin.**
///
/// Barcha capture/update derivation: [ObservationStateDerivation] / [ObservationPipelineService].
class FieldTrustMeta {
  static const String sourceLiveRefresh = ObservationLocationSources.liveRefresh;
  static const String sourceLastKnown = ObservationLocationSources.lastKnown;
  static const String sourceAbsent = ObservationLocationSources.absent;

  static const String warnGpsNoFix = ObservationWarnCodes.gpsNoFix;
  static const String warnGpsStaleFix = ObservationWarnCodes.gpsStaleFix;
  static const String warnGpsMock = ObservationWarnCodes.gpsMock;
  static const String warnGpsLastKnown = ObservationWarnCodes.gpsLastKnown;
  static const String warnGpsImpossibleAccuracy =
      ObservationWarnCodes.gpsImpossibleAccuracy;
  static const String warnGpsSuspectFixTimestamp =
      ObservationWarnCodes.gpsSuspectFixTimestamp;
  static const String warnGpsNullIsland = ObservationWarnCodes.gpsNullIsland;
  static const String warnGpsWeakAccuracyM = ObservationWarnCodes.gpsWeakAccuracyM;

  static const String warnPhotoTinyFile = ObservationWarnCodes.photoTinyFile;

  static const String warnTimeWallFuture = ObservationWarnCodes.timeWallFuture;
  static const String warnTimeWallAncient = ObservationWarnCodes.timeWallAncient;
  static const String warnTimeGpsWallSkew = ObservationWarnCodes.timeGpsWallSkew;

  static const String warnDupClockClose = ObservationWarnCodes.dupClockClose;
  static const String warnDupPhotoSessionHash =
      ObservationWarnCodes.dupPhotoSessionHash;
  static const String warnDupRapidSameHashSignal =
      ObservationWarnCodes.dupRapidSameHashSignal;

  static const String warnRecoveryManualPostEdit =
      ObservationWarnCodes.recoveryManualPostEdit;

  static String warnAxis(String code) => ObservationWarnCodes.warnAxis(code);

  static String warnKind(String code) => ObservationWarnCodes.warnKind(code);

  static List<String> _normalizeWarnings(List<String> raw) =>
      ObservationWarnCodes.normalizeWarnList(raw);

  final String schemaVersion;
  final String locationSource;
  final bool coordinateTrusted;
  final bool gpsFixStale;
  final bool gpsMockSuspected;
  final String? gpsFixUtcIso;
  final double? horizontalAccuracyM;
  final int? captureEpochMs;
  final String? captureWallClockUtcIso;
  final String fieldSessionId;
  final String captureId;
  final bool networkConnected;
  final int? batteryPct;
  final bool altitudeAvailable;
  final int trustScore;
  final List<String> warnings;
  final FieldTrustCategory category;
  final String? imageSha256;
  final int? imageSizeBytes;

  final ObservationDuplicateInfo? observationDuplicate;
  final ObservationProvenance? lastMutationProvenance;
  final ObservationIntegrityInfo? observationIntegrity;

  FieldTrustMeta({
    this.schemaVersion = '3',
    required this.locationSource,
    required this.coordinateTrusted,
    required this.gpsFixStale,
    required this.gpsMockSuspected,
    this.gpsFixUtcIso,
    this.horizontalAccuracyM,
    this.captureEpochMs,
    this.captureWallClockUtcIso,
    required this.fieldSessionId,
    required this.captureId,
    required this.networkConnected,
    this.batteryPct,
    required this.altitudeAvailable,
    required this.trustScore,
    required this.warnings,
    required this.category,
    this.imageSha256,
    this.imageSizeBytes,
    this.observationDuplicate,
    this.lastMutationProvenance,
    this.observationIntegrity,
  });

  static FieldTrustCategory computeCategory({
    required bool coordinateTrusted,
    required String locationSource,
    required bool gpsMockSuspected,
    required bool gpsFixStale,
    required int trustScore,
    required List<String> warnings,
  }) {
    return ObservationStateDerivation.computeCategory(
      coordinateTrusted: coordinateTrusted,
      locationSource: locationSource,
      gpsMockSuspected: gpsMockSuspected,
      gpsFixStale: gpsFixStale,
      trustScore: trustScore,
      warnings: warnings,
    );
  }

  static FieldTrustMeta forCapture({
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
    final wallIso = DateTime.fromMillisecondsSinceEpoch(
      captureWallClockMs,
      isUtc: false,
    ).toUtc().toIso8601String();

    final facts = ObservationRawFacts(
      position: pos == null ? null : PositionLike.fromPosition(pos),
      locationSourceOverride: pos == null ? null : locationSource,
      captureWallClockMs: captureWallClockMs,
      fieldSessionId: fieldSessionId,
      captureId: captureId,
      networkConnected: networkConnected,
      batteryPct: batteryPct,
      lastCaptureEpochMsForDupClock: lastCaptureEpochMs,
      imageSha256: imageSha256,
      imageSizeBytes: imageSizeBytes,
      duplicateSessionHashMatchCaptureId:
          duplicateSessionImageHashMatchCaptureId,
      lastSuccessImageSha256: lastSuccessImageSha256,
      lastSuccessCaptureWallMs: lastSuccessCaptureWallMs,
      provenance:
          const ObservationProvenance(source: ObservationMutationSource.capture),
    );

    final derived = ObservationStateDerivation.deriveObservationState(facts);
    final dup = derived.duplicateInfo.isEmpty ? null : derived.duplicateInfo;

    if (pos == null) {
      return FieldTrustMeta(
        schemaVersion: '3',
        locationSource: sourceAbsent,
        coordinateTrusted: false,
        gpsFixStale: true,
        gpsMockSuspected: false,
        gpsFixUtcIso: null,
        horizontalAccuracyM: null,
        captureEpochMs: captureWallClockMs,
        captureWallClockUtcIso: wallIso,
        fieldSessionId: fieldSessionId,
        captureId: captureId,
        networkConnected: networkConnected,
        batteryPct: batteryPct,
        altitudeAvailable: false,
        trustScore: derived.trustScore,
        warnings: derived.normalizedWarnings,
        category: derived.category,
        imageSha256: imageSha256,
        imageSizeBytes: imageSizeBytes,
        observationDuplicate: dup,
        lastMutationProvenance: derived.provenance,
        observationIntegrity: derived.integrityInfo,
      );
    }

    final src = locationSource ?? sourceLiveRefresh;
    var mock = false;
    try {
      mock = pos.isMocked;
    } catch (_) {}

    final stale =
        DateTime.now().difference(pos.timestamp) > AppTimeouts.gpsFixMaxAge;

    return FieldTrustMeta(
      schemaVersion: '3',
      locationSource: src,
      coordinateTrusted: true,
      gpsFixStale: stale,
      gpsMockSuspected: mock,
      gpsFixUtcIso: pos.timestamp.toUtc().toIso8601String(),
      horizontalAccuracyM: pos.accuracy,
      captureEpochMs: captureWallClockMs,
      captureWallClockUtcIso: wallIso,
      fieldSessionId: fieldSessionId,
      captureId: captureId,
      networkConnected: networkConnected,
      batteryPct: batteryPct,
      altitudeAvailable:
          pos.altitudeAccuracy > 0 && pos.altitudeAccuracy.isFinite,
      trustScore: derived.trustScore,
      warnings: derived.normalizedWarnings,
      category: derived.category,
      imageSha256: imageSha256,
      imageSizeBytes: imageSizeBytes,
      observationDuplicate: dup,
      lastMutationProvenance: derived.provenance,
      observationIntegrity: derived.integrityInfo,
    );
  }

  /// Qo‘lda tahrir — provenance [ObservationMutationSource.manual_edit].
  static FieldTrustMeta degradedAfterManualEdit(FieldTrustMeta m) {
    final derived = ObservationStateDerivation.deriveManualPostEditCore(
      coordinateTrusted: m.coordinateTrusted,
      locationSource: m.locationSource,
      gpsMockSuspected: m.gpsMockSuspected,
      gpsFixStale: m.gpsFixStale,
      priorTrustScore: m.trustScore,
      priorWarnings: m.warnings,
      provenance: const ObservationProvenance(
        source: ObservationMutationSource.manual_edit,
      ),
    );
    return FieldTrustMeta(
      schemaVersion: '3',
      locationSource: m.locationSource,
      coordinateTrusted: m.coordinateTrusted,
      gpsFixStale: m.gpsFixStale,
      gpsMockSuspected: m.gpsMockSuspected,
      gpsFixUtcIso: m.gpsFixUtcIso,
      horizontalAccuracyM: m.horizontalAccuracyM,
      captureEpochMs: m.captureEpochMs,
      captureWallClockUtcIso: m.captureWallClockUtcIso,
      fieldSessionId: m.fieldSessionId,
      captureId: m.captureId,
      networkConnected: m.networkConnected,
      batteryPct: m.batteryPct,
      altitudeAvailable: m.altitudeAvailable,
      trustScore: derived.trustScore,
      warnings: derived.normalizedWarnings,
      category: derived.category,
      imageSha256: m.imageSha256,
      imageSizeBytes: m.imageSizeBytes,
      observationDuplicate: m.observationDuplicate,
      lastMutationProvenance: derived.provenance,
      observationIntegrity: m.observationIntegrity,
    );
  }

  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'src': locationSource,
        'coord_ok': coordinateTrusted,
        'stale': gpsFixStale,
        'mock': gpsMockSuspected,
        if (gpsFixUtcIso != null) 'fix_utc': gpsFixUtcIso,
        if (horizontalAccuracyM != null) 'acc_m': horizontalAccuracyM,
        if (captureEpochMs != null) 'cap_ms': captureEpochMs,
        if (captureWallClockUtcIso != null) 'wall_utc': captureWallClockUtcIso,
        'sess': fieldSessionId,
        'cid': captureId,
        'online': networkConnected,
        if (batteryPct != null) 'bat': batteryPct,
        'alt_ok': altitudeAvailable,
        'trust': trustScore,
        'warn': warnings,
        'cat': category.name.toUpperCase(),
        if (imageSha256 != null) 'img_sha': imageSha256,
        if (imageSizeBytes != null) 'img_bytes': imageSizeBytes,
        if (observationDuplicate != null && !observationDuplicate!.isEmpty)
          ...observationDuplicate!.toJson(),
        if (lastMutationProvenance != null) ...lastMutationProvenance!.toJson(),
        if (observationIntegrity != null) ...observationIntegrity!.toJson(),
        'deriv_v': ObservationDerivationResult.derivationLogicVersion,
      };

  String encode() => jsonEncode(toJson());

  static FieldTrustMeta? decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawWarn = (m['warn'] as List?)?.cast<String>() ?? const [];
      final normalizedWarnings = _normalizeWarnings(rawWarn);
      final coordOk = m['coord_ok'] as bool? ?? true;
      final src = m['src'] as String? ?? 'unknown';
      final mock = m['mock'] as bool? ?? false;
      final stale = m['stale'] as bool? ?? false;
      final ts = m['trust'] as int? ?? 50;
      final cat = ObservationStateDerivation.computeCategory(
        coordinateTrusted: coordOk,
        locationSource: src,
        gpsMockSuspected: mock,
        gpsFixStale: stale,
        trustScore: ts,
        warnings: normalizedWarnings,
      );
      final od = ObservationDuplicateInfo.fromJson(m);
      final op = ObservationProvenance.tryParse(m);
      final oi = ObservationIntegrityInfo.fromJson(m);
      return FieldTrustMeta(
        schemaVersion: m['v'] as String? ?? '1',
        locationSource: src,
        coordinateTrusted: coordOk,
        gpsFixStale: stale,
        gpsMockSuspected: mock,
        gpsFixUtcIso: m['fix_utc'] as String?,
        horizontalAccuracyM: (m['acc_m'] as num?)?.toDouble(),
        captureEpochMs: m['cap_ms'] as int?,
        captureWallClockUtcIso: m['wall_utc'] as String?,
        fieldSessionId: m['sess'] as String? ?? '',
        captureId: m['cid'] as String? ?? '',
        networkConnected: m['online'] as bool? ?? true,
        batteryPct: m['bat'] as int?,
        altitudeAvailable: m['alt_ok'] as bool? ?? false,
        trustScore: ts,
        warnings: normalizedWarnings,
        category: cat,
        imageSha256: m['img_sha'] as String?,
        imageSizeBytes: m['img_bytes'] as int?,
        observationDuplicate: od.isEmpty ? null : od,
        lastMutationProvenance: op,
        observationIntegrity:
            (oi.storedContentSha256 == null && oi.storedByteLength == null)
                ? null
                : oi,
      );
    } catch (_) {
      return null;
    }
  }

  bool get allowsNullIslandCoordinates =>
      !coordinateTrusted && locationSource == sourceAbsent;
}
