import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../core/diagnostics/app_timeouts.dart';
import 'field_trust_category.dart';

/// Dalada yozilgan yozuv atrofidagi ishonch metadatasi (Hive / sinxron JSON).
/// `category` — bitta normalizatsiyalangan holat; `warnings` — batafsil (cheklangan ro‘yxat).
class FieldTrustMeta {
  static const String sourceLiveRefresh = 'live_refresh';
  static const String sourceLastKnown = 'last_known';
  static const String sourceAbsent = 'absent';

  static const String warnDuplicateTimestamp = 'duplicate_wall_clock';
  static const String warnNoGps = 'no_gps_fix';
  static const String warnStaleFix = 'stale_fix';
  static const String warnMock = 'mock_location';
  static const String warnLastKnown = 'last_known_source';
  static const String warnImpossibleAccuracy = 'impossible_accuracy';
  static const String warnSuspectTimestamp = 'suspect_fix_timestamp';
  static const String warnNullIsland = 'null_island';
  static const String warnWeakAccuracy = 'weak_accuracy_m';
  static const String warnDuplicateImageContent = 'duplicate_image_content';
  static const String warnRapidReshoot = 'rapid_reshoot_same_hash';
  static const String warnTinyImage = 'tiny_image_file';

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

  const FieldTrustMeta({
    this.schemaVersion = '2',
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
  });

  /// Deterministik kategoriya — bir xil kiritmada har doim bir xil chiqadi.
  static FieldTrustCategory computeCategory({
    required bool coordinateTrusted,
    required String locationSource,
    required bool gpsMockSuspected,
    required bool gpsFixStale,
    required int trustScore,
    required List<String> warnings,
  }) {
    if (warnings.contains(warnImpossibleAccuracy) ||
        warnings.contains(warnSuspectTimestamp) ||
        warnings.contains(warnNullIsland)) {
      return FieldTrustCategory.invalid;
    }
    if (gpsMockSuspected) {
      return FieldTrustCategory.mocked;
    }
    if (!coordinateTrusted || locationSource == sourceAbsent) {
      return FieldTrustCategory.partial;
    }
    if (gpsFixStale) {
      return FieldTrustCategory.stale;
    }
    if (trustScore >= 85 && warnings.isEmpty) {
      return FieldTrustCategory.verified;
    }
    return FieldTrustCategory.suspect;
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

    void noteImageIntegrity(List<String> warnings) {
      if (imageSizeBytes != null && imageSizeBytes >= 0 && imageSizeBytes < 256) {
        warnings.add(warnTinyImage);
      }
    }

    if (pos == null) {
      final w = <String>[warnNoGps];
      noteImageIntegrity(w);
      if (duplicateSessionImageHashMatchCaptureId != null) {
        w.add(warnDuplicateImageContent);
      }
      final rapid = lastSuccessImageSha256 != null &&
          imageSha256 != null &&
          lastSuccessImageSha256 == imageSha256 &&
          lastSuccessCaptureWallMs != null &&
          (captureWallClockMs - lastSuccessCaptureWallMs).abs() < 2000;
      if (rapid) {
        w.add(warnRapidReshoot);
      }

      final wd = _dedupeWarnings(w);
      final sc = math.max(0, 22 - (duplicateSessionImageHashMatchCaptureId != null ? 18 : 0) - (rapid ? 15 : 0) - (wd.contains(warnTinyImage) ? 10 : 0));
      final cat = computeCategory(
        coordinateTrusted: false,
        locationSource: sourceAbsent,
        gpsMockSuspected: false,
        gpsFixStale: true,
        trustScore: sc,
        warnings: wd,
      );
      return FieldTrustMeta(
        schemaVersion: '2',
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
        trustScore: sc,
        warnings: wd,
        category: cat,
        imageSha256: imageSha256,
        imageSizeBytes: imageSizeBytes,
      );
    }

    final src = locationSource ?? sourceLiveRefresh;

    var mock = false;
    try {
      mock = pos.isMocked;
    } catch (_) {}

    final fixAge = DateTime.now().difference(pos.timestamp);
    final stale = fixAge > AppTimeouts.gpsFixMaxAge;
    final acc = pos.accuracy;
    final accBad = !acc.isFinite || acc < 0 || acc > 50000;
    final accWeak = acc.isFinite && acc > 50;
    final accVeryWeak = acc.isFinite && acc > 100;

    final tsY = pos.timestamp.toUtc().year;
    final suspectTs = tsY < 1999 || tsY > 2100;

    final nullIsland =
        pos.latitude == 0 && pos.longitude == 0 && src != sourceAbsent;

    final altAvail = pos.altitudeAccuracy > 0 && pos.altitudeAccuracy.isFinite;

    final dupClock = lastCaptureEpochMs != null &&
        (captureWallClockMs - lastCaptureEpochMs).abs() < 800;

    final warnings = <String>[];
    var score = 100;

    if (mock) {
      warnings.add(warnMock);
      score -= 35;
    }
    if (stale) {
      warnings.add(warnStaleFix);
      score -= 22;
    }
    if (src == sourceLastKnown) {
      warnings.add(warnLastKnown);
      score -= 10;
    }
    if (accBad) {
      warnings.add(warnImpossibleAccuracy);
      score -= 28;
    } else {
      if (accVeryWeak) {
        warnings.add(warnWeakAccuracy);
        score -= 14;
      } else if (accWeak) {
        warnings.add(warnWeakAccuracy);
        score -= 7;
      }
    }
    if (suspectTs) {
      warnings.add(warnSuspectTimestamp);
      score -= 25;
    }
    if (nullIsland) {
      warnings.add(warnNullIsland);
      score -= 40;
    }
    if (dupClock) {
      warnings.add(warnDuplicateTimestamp);
      score -= 12;
    }
    if (duplicateSessionImageHashMatchCaptureId != null) {
      warnings.add(warnDuplicateImageContent);
      score -= 20;
    }
    final rapidOk = lastSuccessImageSha256 != null &&
        imageSha256 != null &&
        lastSuccessImageSha256 == imageSha256 &&
        lastSuccessCaptureWallMs != null &&
        (captureWallClockMs - lastSuccessCaptureWallMs).abs() < 2000;
    if (rapidOk) {
      warnings.add(warnRapidReshoot);
      score -= 15;
    }

    noteImageIntegrity(warnings);
    if (warnings.contains(warnTinyImage)) {
      score -= 10;
    }

    score = math.max(0, math.min(100, score));

    final wd = _dedupeWarnings(warnings);
    final cat = computeCategory(
      coordinateTrusted: true,
      locationSource: src,
      gpsMockSuspected: mock,
      gpsFixStale: stale,
      trustScore: score,
      warnings: wd,
    );

    return FieldTrustMeta(
      schemaVersion: '2',
      locationSource: src,
      coordinateTrusted: true,
      gpsFixStale: stale,
      gpsMockSuspected: mock,
      gpsFixUtcIso: pos.timestamp.toUtc().toIso8601String(),
      horizontalAccuracyM: acc,
      captureEpochMs: captureWallClockMs,
      captureWallClockUtcIso: wallIso,
      fieldSessionId: fieldSessionId,
      captureId: captureId,
      networkConnected: networkConnected,
      batteryPct: batteryPct,
      altitudeAvailable: altAvail,
      trustScore: score,
      warnings: wd,
      category: cat,
      imageSha256: imageSha256,
      imageSizeBytes: imageSizeBytes,
    );
  }

  static List<String> _dedupeWarnings(List<String> w) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in w) {
      if (seen.add(e)) {
        out.add(e);
      }
    }
    out.sort();
    return out;
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
      };

  static FieldTrustMeta? decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      final warnings = (m['warn'] as List?)?.cast<String>() ?? const [];
      final coordOk = m['coord_ok'] as bool? ?? true;
      final src = m['src'] as String? ?? 'unknown';
      final mock = m['mock'] as bool? ?? false;
      final stale = m['stale'] as bool? ?? false;
      final ts = m['trust'] as int? ?? 50;
      var cat = _parseStoredCategory(m['cat'] as String?);
      cat ??= computeCategory(
        coordinateTrusted: coordOk,
        locationSource: src,
        gpsMockSuspected: mock,
        gpsFixStale: stale,
        trustScore: ts,
        warnings: warnings,
      );
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
        warnings: warnings,
        category: cat,
        imageSha256: m['img_sha'] as String?,
        imageSizeBytes: m['img_bytes'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  static FieldTrustCategory? _parseStoredCategory(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final u = raw.toUpperCase();
    for (final c in FieldTrustCategory.values) {
      if (c.name.toUpperCase() == u) return c;
    }
    return null;
  }

  String encode() => jsonEncode(toJson());

  bool get allowsNullIslandCoordinates =>
      !coordinateTrusted && locationSource == sourceAbsent;
}
