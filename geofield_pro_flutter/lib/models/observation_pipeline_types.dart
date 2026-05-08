import 'field_trust_category.dart';

/// GPS manbai qatorlari — [FieldTrustMeta] bilan mos (backward compat).
abstract final class ObservationLocationSources {
  static const liveRefresh = 'live_refresh';
  static const lastKnown = 'last_known';
  static const absent = 'absent';
}
enum ObservationMutationSource {
  capture,
  manual_edit,
  /// Bulut/Hive import yoki fayldan yuklash (kalit so‘z `import` bo‘lmasligi uchun).
  fromImport,
  sync_merge,
  recovery,
  migration,
  export_repair,
}

/// Mantiqiy takror — **bir xil geologiya yoki “haqiqiy takror” degani emas**.
/// Faqat texnik signal (bayt mosligi / vaqt / tezlik).
enum ObservationDuplicateType {
  none,

  /// Sessiyada kontent hash to‘liq mos — **byte-identical file**, geologik xulosaga yol qo‘ymaydi.
  byte_identical,

  /// Qisqa vaqt ichida xuddi shu hash — surat qayta ishlatish / tez qayta bosish shubhasi.
  rapid_capture_similarity,

  /// Devor vaqti juda yaqin — **mantiqiy takror sababi noma’lum**.
  logical_duplicate_unknown,
}

/// Takror bog‘lanish — “silently discard” o‘rniga annotatsiya.
class ObservationDuplicateInfo {
  final String? duplicateGroupId;
  final ObservationDuplicateType duplicateType;
  final String? canonicalObservationId;
  final List<String> hashMatchedObservationIds;

  const ObservationDuplicateInfo({
    this.duplicateGroupId,
    this.duplicateType = ObservationDuplicateType.none,
    this.canonicalObservationId,
    this.hashMatchedObservationIds = const [],
  });

  bool get isEmpty => duplicateType == ObservationDuplicateType.none;

  Map<String, dynamic> toJson() => {
        if (duplicateGroupId != null) 'dup_grp': duplicateGroupId,
        'dup_type': duplicateType.name,
        if (canonicalObservationId != null) 'dup_canon': canonicalObservationId,
        if (hashMatchedObservationIds.isNotEmpty)
          'dup_hash_ids': List<String>.from(hashMatchedObservationIds),
      };

  static ObservationDuplicateInfo fromJson(Map<String, dynamic>? m) {
    if (m == null) return const ObservationDuplicateInfo();
    final t = m['dup_type'] as String?;
    ObservationDuplicateType ty = ObservationDuplicateType.none;
    if (t != null) {
      const legacy = {
        'sessionImageHash': ObservationDuplicateType.byte_identical,
        'rapidSameHashSignal':
            ObservationDuplicateType.rapid_capture_similarity,
        'wallClockClose': ObservationDuplicateType.logical_duplicate_unknown,
      };
      final fromLegacy = legacy[t];
      if (fromLegacy != null) {
        ty = fromLegacy;
      } else {
        for (final v in ObservationDuplicateType.values) {
          if (v.name == t) {
            ty = v;
            break;
          }
        }
      }
    }
    final ids = (m['dup_hash_ids'] as List?)?.cast<String>() ?? const <String>[];
    return ObservationDuplicateInfo(
      duplicateGroupId: m['dup_grp'] as String?,
      duplicateType: ty,
      canonicalObservationId: m['dup_canon'] as String?,
      hashMatchedObservationIds: ids,
    );
  }
}

/// Hash va hajm — **moslik / buzilish signal**; bu “xavfsiz dalil” emas.
class ObservationIntegrityInfo {
  final String? storedContentSha256;
  final int? storedByteLength;
  final bool fileMissing;
  final bool hashMismatch;

  const ObservationIntegrityInfo({
    this.storedContentSha256,
    this.storedByteLength,
    this.fileMissing = false,
    this.hashMismatch = false,
  });

  Map<String, dynamic> toJson() => {
        if (storedContentSha256 != null) 'int_sha': storedContentSha256,
        if (storedByteLength != null) 'int_bytes': storedByteLength,
        'int_file_miss': fileMissing,
        'int_hash_miss': hashMismatch,
      };

  static ObservationIntegrityInfo fromJson(Map<String, dynamic>? m) {
    if (m == null) return const ObservationIntegrityInfo();
    return ObservationIntegrityInfo(
      storedContentSha256: m['int_sha'] as String?,
      storedByteLength: m['int_bytes'] as int?,
      fileMissing: m['int_file_miss'] as bool? ?? false,
      hashMismatch: m['int_hash_miss'] as bool? ?? false,
    );
  }
}

/// Qayerdan kelgan o‘zgarish.
class ObservationProvenance {
  final ObservationMutationSource source;
  final String? note;

  const ObservationProvenance({
    required this.source,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'prov': source.name,
        if (note != null && note!.isNotEmpty) 'prov_note': note,
      };

  static ObservationProvenance? tryParse(Map<String, dynamic>? m) {
    if (m == null) return null;
    final raw = m['prov'] as String?;
    if (raw == null) return null;
    for (final s in ObservationMutationSource.values) {
      if (s.name == raw) {
        return ObservationProvenance(
          source: s,
          note: m['prov_note'] as String?,
        );
      }
    }
    return null;
  }
}

/// Splash / inflight tiklash holati (lifecycle uchun).
class ObservationRecoveryContext {
  final String? inflightCaptureId;
  final int? startedWallMs;
  final String? sessionId;
  final String? photoPath;
  final int? ageMinutes;
  final bool photoPathExists;

  const ObservationRecoveryContext({
    this.inflightCaptureId,
    this.startedWallMs,
    this.sessionId,
    this.photoPath,
    this.ageMinutes,
    this.photoPathExists = false,
  });

  static ObservationRecoveryContext fromInflightMap(Map<String, dynamic> m) {
    return ObservationRecoveryContext(
      inflightCaptureId: m['capture_id'] as String?,
      startedWallMs: m['started_ms'] as int?,
      sessionId: m['session'] as String?,
      photoPath: m['photo_path'] as String?,
    );
  }
}

/// Derivation natijasi — bitta deterministik chiqish.
class ObservationDerivationResult {
  static const int derivationLogicVersion = 1;

  final List<String> normalizedWarnings;
  final FieldTrustCategory category;
  /// Diagnostika: saralash / eksport ixtiyoriy eslatma. **Category bilan tenglashtirilmasin.**
  final int trustScore;
  final ObservationProvenance provenance;
  final ObservationDuplicateInfo duplicateInfo;
  final ObservationIntegrityInfo integrityInfo;
  final DateTime derivedAt;
  final int derivationVersion;

  const ObservationDerivationResult({
    required this.normalizedWarnings,
    required this.category,
    required this.trustScore,
    required this.provenance,
    required this.duplicateInfo,
    required this.integrityInfo,
    required this.derivedAt,
    this.derivationVersion = derivationLogicVersion,
  });
}

/// Pipeline kirish faktlari (RAW → derivation).
class ObservationRawFacts {
  final PositionLike? position;
  final String? locationSourceOverride;
  final int captureWallClockMs;
  final String fieldSessionId;
  final String captureId;
  final bool networkConnected;
  final int? batteryPct;
  final int? lastCaptureEpochMsForDupClock;
  final String? imageSha256;
  final int? imageSizeBytes;
  final String? duplicateSessionHashMatchCaptureId;
  final String? lastSuccessImageSha256;
  final int? lastSuccessCaptureWallMs;
  final ObservationProvenance provenance;

  const ObservationRawFacts({
    this.position,
    this.locationSourceOverride,
    required this.captureWallClockMs,
    required this.fieldSessionId,
    required this.captureId,
    required this.networkConnected,
    this.batteryPct,
    this.lastCaptureEpochMsForDupClock,
    this.imageSha256,
    this.imageSizeBytes,
    this.duplicateSessionHashMatchCaptureId,
    this.lastSuccessImageSha256,
    this.lastSuccessCaptureWallMs,
    required this.provenance,
  });
}

/// GPS/vaqt uchun [Position] ni to‘g‘ridan-to‘g‘ri import qilmaslik — derivation testlari uchun.
class PositionLike {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isMocked;
  final double altitudeAccuracy;

  const PositionLike({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.isMocked,
    required this.altitudeAccuracy,
  });

  factory PositionLike.fromPosition(dynamic pos) {
    // geolocator Position
    final p = pos as dynamic;
    return PositionLike(
      latitude: p.latitude as double,
      longitude: p.longitude as double,
      altitude: p.altitude as double,
      accuracy: p.accuracy as double,
      timestamp: p.timestamp as DateTime,
      isMocked: p.isMocked as bool,
      altitudeAccuracy: p.altitudeAccuracy as double,
    );
  }
}
