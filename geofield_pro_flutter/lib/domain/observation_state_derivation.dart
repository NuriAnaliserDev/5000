import 'dart:math' as math;

import '../core/diagnostics/app_timeouts.dart';
import '../models/field_trust_category.dart';
import '../models/observation_pipeline_types.dart';
import '../models/observation_warn_codes.dart';

/// Bitta kirish nuqtasi: RAW faktlardan category, score, warnings, duplicate, integrity.
abstract final class ObservationStateDerivation {
  static FieldTrustCategory computeCategory({
    required bool coordinateTrusted,
    required String locationSource,
    required bool gpsMockSuspected,
    required bool gpsFixStale,
    required int trustScore,
    required List<String> warnings,
  }) {
    final w = ObservationWarnCodes.normalizeWarnList(warnings);
    if (w.contains(ObservationWarnCodes.gpsImpossibleAccuracy) ||
        w.contains(ObservationWarnCodes.gpsSuspectFixTimestamp) ||
        w.contains(ObservationWarnCodes.gpsNullIsland) ||
        w.contains(ObservationWarnCodes.timeWallFuture)) {
      return FieldTrustCategory.invalid;
    }
    if (gpsMockSuspected || w.contains(ObservationWarnCodes.gpsMock)) {
      return FieldTrustCategory.mocked;
    }
    if (!coordinateTrusted || locationSource == ObservationLocationSources.absent) {
      return FieldTrustCategory.partial;
    }
    if (gpsFixStale || w.contains(ObservationWarnCodes.gpsStaleFix)) {
      return FieldTrustCategory.stale;
    }
    if (w.contains(ObservationWarnCodes.timeWallAncient) ||
        w.contains(ObservationWarnCodes.timeGpsWallSkew)) {
      return FieldTrustCategory.suspect;
    }
    if (trustScore >= 85 && w.isEmpty) {
      return FieldTrustCategory.verified;
    }
    return FieldTrustCategory.suspect;
  }

  static void _noteTimeTrustWall(List<String> warnings, int captureWallClockMs) {
    final wall = DateTime.fromMillisecondsSinceEpoch(captureWallClockMs);
    final now = DateTime.now();
    if (wall.isAfter(now.add(const Duration(hours: 24)))) {
      warnings.add(ObservationWarnCodes.timeWallFuture);
    }
    if (wall.year < 1990) {
      warnings.add(ObservationWarnCodes.timeWallAncient);
    }
  }

  static void _noteGpsWallSkew(
    List<String> warnings,
    PositionLike pos,
    int captureWallClockMs,
  ) {
    final wall = DateTime.fromMillisecondsSinceEpoch(captureWallClockMs);
    final skewMin = wall.difference(pos.timestamp).inMinutes.abs();
    if (skewMin > 120) {
      warnings.add(ObservationWarnCodes.timeGpsWallSkew);
    }
  }

  static List<String> _dedupeSorted(List<String> w) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in w) {
      if (seen.add(e)) out.add(e);
    }
    out.sort();
    return out;
  }

  static ObservationDuplicateInfo _buildDuplicateInfo({
    required String sessionId,
    required String captureId,
    required String? imageSha256,
    required String? duplicateSessionHashMatchCaptureId,
    required bool rapidSignal,
    required bool dupClock,
  }) {
    if (imageSha256 == null || imageSha256.isEmpty) {
      return const ObservationDuplicateInfo();
    }
    final ids = <String>{captureId};
    if (duplicateSessionHashMatchCaptureId != null) {
      ids.add(duplicateSessionHashMatchCaptureId);
    }
    final sortedIds = ids.toList()..sort();

    if (duplicateSessionHashMatchCaptureId != null) {
      final grp = 'h_${sessionId.hashCode.abs()}_${imageSha256.hashCode.abs()}';
      return ObservationDuplicateInfo(
        duplicateGroupId: grp,
        duplicateType: ObservationDuplicateType.sessionImageHash,
        canonicalObservationId: duplicateSessionHashMatchCaptureId,
        hashMatchedObservationIds: sortedIds,
      );
    }
    if (rapidSignal) {
      final grp = 'r_${sessionId.hashCode.abs()}_${imageSha256.hashCode.abs()}';
      return ObservationDuplicateInfo(
        duplicateGroupId: grp,
        duplicateType: ObservationDuplicateType.rapidSameHashSignal,
        canonicalObservationId: null,
        hashMatchedObservationIds: sortedIds.toList(),
      );
    }
    if (dupClock) {
      return ObservationDuplicateInfo(
        duplicateGroupId: 'c_${captureId.hashCode.abs()}',
        duplicateType: ObservationDuplicateType.wallClockClose,
        canonicalObservationId: null,
        hashMatchedObservationIds: [captureId],
      );
    }
    return const ObservationDuplicateInfo();
  }

  static ObservationIntegrityInfo _integrityFromFacts(ObservationRawFacts facts) {
    return ObservationIntegrityInfo(
      storedContentSha256: facts.imageSha256,
      storedByteLength: facts.imageSizeBytes,
    );
  }

  /// Asosiy deterministik derivation: bir xil kirish → bir xil chiqish.
  static ObservationDerivationResult deriveObservationState(
    ObservationRawFacts facts,
  ) {
    final derivedAt = DateTime.now().toUtc();
    final provenance = facts.provenance;

    void notePhoto(List<String> w) {
      final sz = facts.imageSizeBytes;
      if (sz != null && sz >= 0 && sz < 256) {
        w.add(ObservationWarnCodes.photoTinyFile);
      }
    }

    final pos = facts.position;
    if (pos == null) {
      final w = <String>[ObservationWarnCodes.gpsNoFix];
      _noteTimeTrustWall(w, facts.captureWallClockMs);
      notePhoto(w);
      if (facts.duplicateSessionHashMatchCaptureId != null) {
        w.add(ObservationWarnCodes.dupPhotoSessionHash);
      }
      final rapid = facts.lastSuccessImageSha256 != null &&
          facts.imageSha256 != null &&
          facts.lastSuccessImageSha256 == facts.imageSha256 &&
          facts.lastSuccessCaptureWallMs != null &&
          (facts.captureWallClockMs - facts.lastSuccessCaptureWallMs!).abs() <
              2000;
      if (rapid) {
        w.add(ObservationWarnCodes.dupRapidSameHashSignal);
      }

      final wd = _dedupeSorted(w);
      final sc = math.max(
        0,
        22 -
            (facts.duplicateSessionHashMatchCaptureId != null ? 18 : 0) -
            (rapid ? 15 : 0) -
            (wd.contains(ObservationWarnCodes.photoTinyFile) ? 10 : 0) -
            (wd.contains(ObservationWarnCodes.timeWallFuture) ? 30 : 0) -
            (wd.contains(ObservationWarnCodes.timeWallAncient) ? 12 : 0),
      );
      final cat = computeCategory(
        coordinateTrusted: false,
        locationSource: ObservationLocationSources.absent,
        gpsMockSuspected: false,
        gpsFixStale: true,
        trustScore: sc,
        warnings: wd,
      );
      final dup = _buildDuplicateInfo(
        sessionId: facts.fieldSessionId,
        captureId: facts.captureId,
        imageSha256: facts.imageSha256,
        duplicateSessionHashMatchCaptureId:
            facts.duplicateSessionHashMatchCaptureId,
        rapidSignal: rapid,
        dupClock: false,
      );
      return ObservationDerivationResult(
        normalizedWarnings: ObservationWarnCodes.normalizeWarnList(wd),
        category: cat,
        trustScore: sc,
        provenance: provenance,
        duplicateInfo: dup,
        integrityInfo: _integrityFromFacts(facts),
        derivedAt: derivedAt,
      );
    }

    final src =
        facts.locationSourceOverride ?? ObservationLocationSources.liveRefresh;

    var mock = pos.isMocked;

    final fixAge = DateTime.now().difference(pos.timestamp);
    final stale = fixAge > AppTimeouts.gpsFixMaxAge;
    final acc = pos.accuracy;
    final accBad = !acc.isFinite || acc < 0 || acc > 50000;
    final accWeak = acc.isFinite && acc > 50;
    final accVeryWeak = acc.isFinite && acc > 100;

    final tsY = pos.timestamp.toUtc().year;
    final suspectTs = tsY < 1999 || tsY > 2100;

    final nullIsland = pos.latitude == 0 &&
        pos.longitude == 0 &&
        src != ObservationLocationSources.absent;

    final dupClock = facts.lastCaptureEpochMsForDupClock != null &&
        (facts.captureWallClockMs - facts.lastCaptureEpochMsForDupClock!).abs() <
            800;

    final warnings = <String>[];
    var score = 100;

    _noteTimeTrustWall(warnings, facts.captureWallClockMs);
    _noteGpsWallSkew(warnings, pos, facts.captureWallClockMs);

    if (mock) {
      warnings.add(ObservationWarnCodes.gpsMock);
      score -= 35;
    }
    if (stale) {
      warnings.add(ObservationWarnCodes.gpsStaleFix);
      score -= 22;
    }
    if (src == ObservationLocationSources.lastKnown) {
      warnings.add(ObservationWarnCodes.gpsLastKnown);
      score -= 10;
    }
    if (accBad) {
      warnings.add(ObservationWarnCodes.gpsImpossibleAccuracy);
      score -= 28;
    } else {
      if (accVeryWeak) {
        warnings.add(ObservationWarnCodes.gpsWeakAccuracyM);
        score -= 14;
      } else if (accWeak) {
        warnings.add(ObservationWarnCodes.gpsWeakAccuracyM);
        score -= 7;
      }
    }
    if (suspectTs) {
      warnings.add(ObservationWarnCodes.gpsSuspectFixTimestamp);
      score -= 25;
    }
    if (nullIsland) {
      warnings.add(ObservationWarnCodes.gpsNullIsland);
      score -= 40;
    }
    if (dupClock) {
      warnings.add(ObservationWarnCodes.dupClockClose);
      score -= 12;
    }
    if (facts.duplicateSessionHashMatchCaptureId != null) {
      warnings.add(ObservationWarnCodes.dupPhotoSessionHash);
      score -= 20;
    }
    final rapidOk = facts.lastSuccessImageSha256 != null &&
        facts.imageSha256 != null &&
        facts.lastSuccessImageSha256 == facts.imageSha256 &&
        facts.lastSuccessCaptureWallMs != null &&
        (facts.captureWallClockMs - facts.lastSuccessCaptureWallMs!).abs() <
            2000;
    if (rapidOk) {
      warnings.add(ObservationWarnCodes.dupRapidSameHashSignal);
      score -= 15;
    }

    notePhoto(warnings);
    if (warnings.contains(ObservationWarnCodes.photoTinyFile)) {
      score -= 10;
    }
    if (warnings.contains(ObservationWarnCodes.timeWallFuture)) {
      score -= 30;
    }
    if (warnings.contains(ObservationWarnCodes.timeWallAncient)) {
      score -= 12;
    }
    if (warnings.contains(ObservationWarnCodes.timeGpsWallSkew)) {
      score -= 14;
    }

    score = math.max(0, math.min(100, score));

    final wd = _dedupeSorted(warnings);
    final cat = computeCategory(
      coordinateTrusted: true,
      locationSource: src,
      gpsMockSuspected: mock,
      gpsFixStale: stale,
      trustScore: score,
      warnings: wd,
    );

    final dup = _buildDuplicateInfo(
      sessionId: facts.fieldSessionId,
      captureId: facts.captureId,
      imageSha256: facts.imageSha256,
      duplicateSessionHashMatchCaptureId:
          facts.duplicateSessionHashMatchCaptureId,
      rapidSignal: rapidOk,
      dupClock: dupClock,
    );

    return ObservationDerivationResult(
      normalizedWarnings: ObservationWarnCodes.normalizeWarnList(wd),
      category: cat,
      trustScore: score,
      provenance: provenance,
      duplicateInfo: dup,
      integrityInfo: _integrityFromFacts(facts),
      derivedAt: derivedAt,
    );
  }

  /// Qo‘lda tahrir — mavjud bayroqlar saqlanadi, `recovery_manual_post_edit` qo‘shiladi.
  static ObservationDerivationResult deriveManualPostEditCore({
    required bool coordinateTrusted,
    required String locationSource,
    required bool gpsMockSuspected,
    required bool gpsFixStale,
    required int priorTrustScore,
    required List<String> priorWarnings,
    ObservationProvenance? provenance,
  }) {
    final derivedAt = DateTime.now().toUtc();
    if (priorWarnings.contains(ObservationWarnCodes.recoveryManualPostEdit)) {
      final w = ObservationWarnCodes.normalizeWarnList(priorWarnings);
      return ObservationDerivationResult(
        normalizedWarnings: w,
        category: computeCategory(
          coordinateTrusted: coordinateTrusted,
          locationSource: locationSource,
          gpsMockSuspected: gpsMockSuspected,
          gpsFixStale: gpsFixStale,
          trustScore: priorTrustScore,
          warnings: w,
        ),
        trustScore: priorTrustScore,
        provenance: provenance ??
            const ObservationProvenance(source: ObservationMutationSource.manual_edit),
        duplicateInfo: const ObservationDuplicateInfo(),
        integrityInfo: const ObservationIntegrityInfo(),
        derivedAt: derivedAt,
      );
    }
    final w = ObservationWarnCodes.normalizeWarnList([
      ...priorWarnings,
      ObservationWarnCodes.recoveryManualPostEdit,
    ]);
    final score = math.max(0, priorTrustScore - 20);
    final cat = computeCategory(
      coordinateTrusted: coordinateTrusted,
      locationSource: locationSource,
      gpsMockSuspected: gpsMockSuspected,
      gpsFixStale: gpsFixStale,
      trustScore: score,
      warnings: w,
    );
    return ObservationDerivationResult(
      normalizedWarnings: w,
      category: cat,
      trustScore: score,
      provenance: provenance ??
          const ObservationProvenance(source: ObservationMutationSource.manual_edit),
      duplicateInfo: const ObservationDuplicateInfo(),
      integrityInfo: const ObservationIntegrityInfo(),
      derivedAt: derivedAt,
    );
  }
}
