import 'package:flutter/foundation.dart';

import 'memory_rss_stub.dart' if (dart.library.io) 'memory_rss_io.dart' as rss;

/// Web’da `null`; VM’da RSS (bytes).
Map<String, Object?>? memoryPayloadForDiagnostics() {
  if (kIsWeb) return null;
  return rss.diagnosticMemoryRssPayload();
}
