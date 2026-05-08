import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../core/diagnostics/app_timeouts.dart';

/// Dalada yozilgan yozuv atrofidagi ishonch metadatasi (Hive / sinxron JSON).
/// Bu serverni aldashning oldini olmaydi — faqat iz va keyingi filtrlash uchun.
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
  });

  /// Bitta “suratdan stansiya” yoki maydon yozuvi uchun to‘liq metadata + skor.
  /// Rad etmaydi — faqat ogohlantirish va ball beradi (0–100).
  static FieldTrustMeta forCapture({
    Position? pos,
    String? locationSource,
    required int captureWallClockMs,
    required String fieldSessionId,
    required String captureId,
    required bool networkConnected,
    int? batteryPct,
    int? lastCaptureEpochMs,
  }) {
    final wallIso = DateTime.fromMillisecondsSinceEpoch(
      captureWallClockMs,
      isUtc: false,
    ).toUtc().toIso8601String();

    if (pos == null) {
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
        trustScore: 22,
        warnings: [warnNoGps],
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

    score = math.max(0, math.min(100, score));

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
      warnings: warnings,
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
      };

  static FieldTrustMeta? decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FieldTrustMeta(
        schemaVersion: m['v'] as String? ?? '1',
        locationSource: m['src'] as String? ?? 'unknown',
        coordinateTrusted: m['coord_ok'] as bool? ?? true,
        gpsFixStale: m['stale'] as bool? ?? false,
        gpsMockSuspected: m['mock'] as bool? ?? false,
        gpsFixUtcIso: m['fix_utc'] as String?,
        horizontalAccuracyM: (m['acc_m'] as num?)?.toDouble(),
        captureEpochMs: m['cap_ms'] as int?,
        captureWallClockUtcIso: m['wall_utc'] as String?,
        fieldSessionId: m['sess'] as String? ?? '',
        captureId: m['cid'] as String? ?? '',
        networkConnected: m['online'] as bool? ?? true,
        batteryPct: m['bat'] as int?,
        altitudeAvailable: m['alt_ok'] as bool? ?? false,
        trustScore: m['trust'] as int? ?? 50,
        warnings: (m['warn'] as List?)?.cast<String>() ?? const [],
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  /// Validator: GPS yo‘qligi aniq belgilangan bo‘lsa 0°, 0° placeholder ruxsat.
  bool get allowsNullIslandCoordinates =>
      !coordinateTrusted && locationSource == sourceAbsent;
}
