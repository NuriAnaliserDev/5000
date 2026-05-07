import 'dart:io' show ProcessInfo;

Map<String, Object?>? diagnosticMemoryRssPayload() {
  try {
    final b = ProcessInfo.currentRss;
    if (b <= 0) return null;
    return {'rss_bytes': b};
  } catch (_) {
    return null;
  }
}
