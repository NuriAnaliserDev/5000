/// Yagona ogohlantirish katalogi — pipeline va eksport bilan sinxron.
abstract final class ObservationWarnCodes {
  static const gpsNoFix = 'gps_no_fix';
  static const gpsStaleFix = 'gps_stale_fix';
  static const gpsMock = 'gps_mock';
  static const gpsLastKnown = 'gps_last_known';
  static const gpsImpossibleAccuracy = 'gps_impossible_accuracy';
  static const gpsSuspectFixTimestamp = 'gps_suspect_fix_ts';
  static const gpsNullIsland = 'gps_null_island';
  static const gpsWeakAccuracyM = 'gps_weak_accuracy_m';

  static const photoTinyFile = 'photo_tiny_file';

  static const timeWallFuture = 'time_wall_future';
  static const timeWallAncient = 'time_wall_ancient';
  static const timeGpsWallSkew = 'time_gps_wall_skew';

  static const dupClockClose = 'dup_clock_close';
  static const dupPhotoSessionHash = 'dup_photo_session_hash';
  static const dupRapidSameHashSignal = 'dup_rapid_same_hash_signal';

  static const recoveryManualPostEdit = 'recovery_manual_post_edit';

  static const Map<String, String> legacyToCanonical = {
    'duplicate_wall_clock': dupClockClose,
    'no_gps_fix': gpsNoFix,
    'stale_fix': gpsStaleFix,
    'mock_location': gpsMock,
    'last_known_source': gpsLastKnown,
    'impossible_accuracy': gpsImpossibleAccuracy,
    'suspect_fix_timestamp': gpsSuspectFixTimestamp,
    'null_island': gpsNullIsland,
    'weak_accuracy_m': gpsWeakAccuracyM,
    'duplicate_image_content': dupPhotoSessionHash,
    'rapid_reshoot_same_hash': dupRapidSameHashSignal,
    'tiny_image_file': photoTinyFile,
  };

  /// GPS / PHOTO / TIME / DUPLICATE / RECOVERY / EXPORT / EVENT / HEURISTIC / STATE / OTHER
  static String warnAxis(String code) {
    if (code.startsWith('export_')) return 'EXPORT';
    if (code.startsWith('event_')) return 'EVENT';
    if (code.startsWith('heuristic_')) return 'HEURISTIC';
    if (code.startsWith('state_')) return 'STATE';
    if (code.startsWith('gps_')) return 'GPS';
    if (code.startsWith('photo_')) return 'PHOTO';
    if (code.startsWith('time_')) return 'TIME';
    if (code.startsWith('recovery_')) return 'RECOVERY';
    if (code.startsWith('dup_')) return 'DUPLICATE';
    return 'OTHER';
  }

  /// Uslubiy klassifikatsiya: holat / hodisa / evristik / eksport.
  static String warnKind(String code) {
    final axis = warnAxis(code);
    if (axis == 'EXPORT') return 'export';
    if (axis == 'EVENT') return 'event';
    if (axis == 'HEURISTIC') return 'heuristic';
    if (axis == 'STATE') return 'state';
    if (code.startsWith('dup_rapid_')) return 'heuristic';
    if (code.startsWith('recovery_')) return 'event';
    if (code.startsWith('gps_') ||
        code.startsWith('photo_') ||
        code.startsWith('time_')) {
      return 'state';
    }
    if (code.startsWith('dup_')) return 'state';
    return 'other';
  }

  static List<String> normalizeWarnList(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final c = legacyToCanonical[e] ?? e;
      if (seen.add(c)) out.add(c);
    }
    out.sort();
    return out;
  }
}
