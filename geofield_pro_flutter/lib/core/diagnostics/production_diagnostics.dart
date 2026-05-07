import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'diagnostic_domain.dart';
import 'diagnostic_service.dart';

/// Xizmatlar va mixinlar uchun ingichka API — to‘g‘ridan-to‘g‘ri JSONL yozmaydi.
abstract final class ProductionDiagnostics {
  static Future<void> appLifecycle(String stateName) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.appLifecycle,
      event: 'state_changed',
      phase: stateName,
      includeMemory: false,
    );
  }

  static Future<void> camera(
    String event, {
    String? phase,
    Map<String, Object?>? data,
  }) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.camera,
      event: event,
      phase: phase,
      data: data,
      includeMemory: false,
    );
  }

  static Future<void> gps(
    String event, {
    String? phase,
    Map<String, Object?>? data,
  }) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.gps,
      event: event,
      phase: phase,
      data: data,
      includeMemory: false,
    );
  }

  static Future<void> firebase(
    String event, {
    String? phase,
    Map<String, Object?>? data,
    bool includeMemory = false,
  }) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.firebase,
      event: event,
      phase: phase,
      data: data,
      includeMemory: includeMemory,
    );
  }

  static Future<void> syncFailure(
    String component,
    Object error,
    StackTrace? stack,
  ) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.sync,
      event: 'async_failure',
      phase: component,
      data: {
        'error': error.toString(),
        if (kDebugMode && stack != null) 'stack': stack.toString(),
      },
      includeMemory: false,
    );
  }

  static Future<void> failure(
    String event, {
    String? phase,
    Map<String, Object?>? data,
  }) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.failure,
      event: event,
      phase: phase,
      data: data,
      includeMemory: true,
    );
  }

  /// Stress / iz sorash uchun bir vaqtning RSS yozuvi.
  static Future<void> memoryCheckpoint(String reason) {
    return DiagnosticService.instance.logStructured(
      domain: DiagnosticDomain.startup,
      event: 'memory_checkpoint',
      phase: reason,
      includeMemory: true,
    );
  }
}

/// [WidgetsBindingObserver] — ilova lifecycle (bitta global nuqta).
class AppLifecycleDiagnosticsObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ProductionDiagnostics.appLifecycle(state.name);
  }
}
