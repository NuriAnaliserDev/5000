import 'package:flutter/foundation.dart';
import 'app_error.dart';
import '../diagnostics/diagnostic_service.dart';

class ErrorLogger {
  static void log(AppError error) {
    // 1. Lokal log faylga yozish (Offline diagnostika uchun)
    DiagnosticService.instance.log(
      '${error.message}${error.originalError != null ? " | Cause: ${error.originalError}" : ""}',
      tag: 'ERROR:${error.category.name}',
    );

    if (kDebugMode) {
      debugPrint('🔴 ERROR [${error.category.name}]: ${error.message}');
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
      {ErrorCategory category = ErrorCategory.unknown, String? customMessage}) {
    final error = AppError(
      customMessage ?? e.toString(),
      category: category,
      originalError: e,
      stackTrace: st,
    );
    log(error);
  }
}
