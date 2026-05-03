import 'package:flutter/foundation.dart';
import 'app_error.dart';

class ErrorLogger {
  static void log(AppError error) {
    if (kDebugMode) {
      debugPrint('🔴 ERROR [${error.category.name}]: ${error.message}');
      if (error.originalError != null) {
        debugPrint('Cause: ${error.originalError}');
      }
      if (error.stackTrace != null) {
        debugPrint('Stack: ${error.stackTrace}');
      }
    }
    // Buni kelajakda Sentry yoki Firebase Crashlytics ga yuborish mumkin
  }

  static void record(Object e, StackTrace? st, {ErrorCategory category = ErrorCategory.unknown, String? customMessage}) {
    final error = AppError(
      customMessage ?? e.toString(),
      category: category,
      originalError: e,
      stackTrace: st,
    );
    log(error);
  }
}
