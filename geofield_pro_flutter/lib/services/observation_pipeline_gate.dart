import 'dart:async';

import '../core/diagnostics/production_diagnostics.dart';

/// Kanonik derivation ichida ekanligini kuzatish — tashqarida chaqiruvlarni diagnostika qiladi.
abstract final class ObservationPipelineGate {
  static int _depth = 0;

  static int get depth => _depth;

  static bool get isActive => _depth > 0;

  static R run<R>(R Function() fn) {
    _depth++;
    try {
      return fn();
    } finally {
      _depth--;
    }
  }

  /// Ruxsat etilgan yo‘l — log yozilmaydi.
  static Future<R> runAsync<R>(Future<R> Function() fn) async {
    _depth++;
    try {
      return await fn();
    } finally {
      _depth--;
    }
  }

  static void logLegacyPathIfUnsealed(String path) {
    if (isActive) return;
    unawaited(
      ProductionDiagnostics.storage(
        'legacy_observation_mutation_path',
        data: {'path': path},
      ),
    );
  }
}
