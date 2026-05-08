import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../core/diagnostics/app_timeouts.dart';

/// Dalada yozilgan nuqta atrofidagi ishonch chegarasi uchun ixcham metadata (Hive/Firestore sinxron).
///
/// Kriptografik imzo emas — izchil iz va keyingi tahlil uchun.
class FieldTrustMeta {
  static const String sourceLiveRefresh = 'live_refresh';
  static const String sourceLastKnown = 'last_known';
  static const String sourceAbsent = 'absent';

  final String schemaVersion;
  final String locationSource;
  final bool coordinateTrusted;
  final bool gpsFixStale;
  final bool gpsMockSuspected;
  final String? gpsFixUtcIso;
  final double? horizontalAccuracyM;
  final int? captureEpochMs;

  const FieldTrustMeta({
    this.schemaVersion = '1',
    required this.locationSource,
    required this.coordinateTrusted,
    required this.gpsFixStale,
    required this.gpsMockSuspected,
    this.gpsFixUtcIso,
    this.horizontalAccuracyM,
    this.captureEpochMs,
  });

  /// GPS umuman bo‘lmaganda — koordinata raqamiy jihatdan 0,0 bo‘lishi mumkin, lekin ishonchsiz.
  static FieldTrustMeta absent({int? captureEpochMs}) => FieldTrustMeta(
        locationSource: sourceAbsent,
        coordinateTrusted: false,
        gpsFixStale: true,
        gpsMockSuspected: false,
        gpsFixUtcIso: null,
        horizontalAccuracyM: null,
        captureEpochMs: captureEpochMs,
      );

  static FieldTrustMeta fromPosition(
    Position pos, {
    required String locationSource,
    int? captureEpochMs,
  }) {
    final age = DateTime.now().difference(pos.timestamp);
    final stale = age > AppTimeouts.gpsFixMaxAge;
    var mock = false;
    try {
      mock = pos.isMocked;
    } catch (_) {}

    return FieldTrustMeta(
      locationSource: locationSource,
      coordinateTrusted: true,
      gpsFixStale: stale,
      gpsMockSuspected: mock,
      gpsFixUtcIso: pos.timestamp.toUtc().toIso8601String(),
      horizontalAccuracyM: pos.accuracy,
      captureEpochMs: captureEpochMs,
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
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  /// Validator: faqat GPS yo‘qligi aniq belgilangan bo‘lsa 0°, 0° ruxsat.
  bool get allowsNullIslandCoordinates =>
      !coordinateTrusted && locationSource == sourceAbsent;
}
