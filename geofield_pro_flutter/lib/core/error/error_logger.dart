import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'error_mapper.dart';
import '../diagnostics/diagnostic_service.dart';

class ErrorLogger {
  static void log(AppError error) {
    // 1. Lokal log faylga yozish (Offline diagnostika uchun)
    DiagnosticService.instance.log(
      '${error.userMessage}${error.devMessage != null ? " | DevMsg: ${error.devMessage}" : ""}${error.originalError != null ? " | Cause: ${error.originalError}" : ""}',
      tag: 'ERROR:${error.category.name}:${error.severity.name}',
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
