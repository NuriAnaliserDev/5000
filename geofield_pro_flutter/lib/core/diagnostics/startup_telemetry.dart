import 'diagnostic_service.dart';
import 'diagnostic_domain.dart';

/// Ilova jarayoni boshidan millisekundlar (`Stopwatch`).
abstract final class StartupTelemetry {
  static final Stopwatch _sw = Stopwatch();
  static bool _started = false;

  /// [main] ichida `ensureInitialized` dan keyin chaqiring.
  static void onProcessStart() {
    if (_started) return;
    _started = true;
    _sw.start();
    DiagnosticService.instance.enqueueStructured(
      domain: DiagnosticDomain.startup,
      event: 'process_start',
      payload: {'monotonic_ms': 0},
    );
  }

  static int get elapsedMs => _sw.elapsedMilliseconds;

  static void milestone(String name, {Map<String, Object?>? extra}) {
    DiagnosticService.instance.enqueueStructured(
      domain: DiagnosticDomain.startup,
      event: 'milestone',
      phase: name,
      payload: {
        'elapsed_ms': elapsedMs,
        if (extra != null) ...extra,
      },
    );
  }
}
