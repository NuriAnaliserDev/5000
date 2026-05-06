/// Sinxronizatsiya paytida konfliktlarni deterministik hal qilish uchun yordamchi util
class SyncUtils {
  /// Qaysi record yutishini aniqlaydi (Deterministic tie-breaker)
  /// 1. Higher version wins
  /// 2. If version equal: higher updatedAt wins
  /// 3. If still equal: lexicographical deviceId wins
  static bool shouldRemoteOverwriteLocal({
    required int localVersion,
    required DateTime? localUpdatedAt,
    required String? localDeviceId,
    required int remoteVersion,
    required DateTime? remoteUpdatedAt,
    required String? remoteDeviceId,
  }) {
    if (remoteVersion > localVersion) return true;
    if (remoteVersion < localVersion) return false;

    // Versiyalar teng bo'lsa (Tie-break)
    final localTime = localUpdatedAt?.millisecondsSinceEpoch ?? 0;
    final remoteTime = remoteUpdatedAt?.millisecondsSinceEpoch ?? 0;

    if (remoteTime > localTime) return true;
    if (remoteTime < localTime) return false;

    // Vaqtlar ham teng bo'lsa (nihoyatda kam holat), deviceId bo'yicha deterministik tanlov
    final lId = localDeviceId ?? '';
    final rId = remoteDeviceId ?? '';
    return rId.compareTo(lId) > 0;
  }
}
