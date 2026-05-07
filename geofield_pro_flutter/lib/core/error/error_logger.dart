import 'dart:async';

import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'error_mapper.dart';
import '../diagnostics/diagnostic_service.dart';
import '../diagnostics/diagnostic_domain.dart';

class ErrorLogger {
  static void log(AppError error) {
    // 1. Lokal log faylga yozish (Offline diagnostika uchun)
    DiagnosticService.instance.log(
      '${error.userMessage}${error.devMessage != null ? " | DevMsg: ${error.devMessage}" : ""}${error.originalError != null ? " | Cause: ${error.originalError}" : ""}',
      tag: 'ERROR:${error.category.name}:${error.severity.name}',
    );

    unawaited(
      DiagnosticService.instance.logStructured(
        domain: DiagnosticDomain.failure,
        event: 'app_error',
        phase: '${error.category.name}|${error.severity.name}',
        data: {
          'user_message': error.userMessage,
          if (error.devMessage != null) 'dev_message': error.devMessage,
          if (error.originalError != null)
            'original_type': error.originalError.runtimeType.toString(),
          if (error.originalError != null)
            'original': error.originalError.toString(),
        },
        includeMemory: error.severity == ErrorSeverity.critical,
      ),
    );

    if (kDebugMode) {
      debugPrint(
          '🔴 ERROR [${error.category.name}|${error.severity.name}]: ${error.userMessage}');
      if (error.devMessage != null) {
        debugPrint('DevMsg: ${error.devMessage}');
      }
      if (error.originalError != null) {
        debugPrint('Cause: ${error.originalError}');
      }
      if (error.stackTrace != null) {
        debugPrint('Stack: ${error.stackTrace}');
      }
    }
    // Kelajakda: FirebaseCrashlytics.instance.recordError(...)
  }

  static void record(Object e, StackTrace? st,
      {ErrorCategory? category, String? customMessage}) {
    final mappedError = ErrorMapper.map(e, st);

    final error = AppError(
      customMessage ?? mappedError.userMessage,
      devMessage: mappedError.devMessage,
      category: category ?? mappedError.category,
      severity: mappedError.severity,
      originalError: mappedError.originalError,
      stackTrace: mappedError.stackTrace,
    );
    log(error);
  }
}
