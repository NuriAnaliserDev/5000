import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../error/app_error.dart';
import '../error/error_logger.dart';

class NetworkExecutor {
  /// Executes an async [action] with exponential backoff retry logic.
  ///
  /// - [maxRetries]: Maximum number of retry attempts.
  /// - [baseDelayMs]: Base delay in milliseconds for the first retry.
  /// - [timeout]: Timeout duration for EACH attempt.
  static Future<T> execute<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    int baseDelayMs = 500,
    Duration timeout = const Duration(seconds: 15),
    String actionName = 'Network Action',
    bool Function(Object)? shouldRetry,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action().timeout(timeout);
      } catch (e, st) {
        attempt++;

        final retryable =
            shouldRetry != null ? shouldRetry(e) : _isNetworkError(e);

        if (!retryable || attempt > maxRetries) {
          ErrorLogger.record(e, st,
              customMessage: '$actionName failed after $attempt attempts.');
          throw _mapToAppError(e, st);
        }

        final delayMs =
            baseDelayMs * pow(2, attempt - 1) + Random().nextInt(200);
        if (kDebugMode) {
          debugPrint(
              '⚠️ $actionName attempt $attempt failed. Retrying in ${delayMs}ms... ($e)');
        }
        await Future<void>.delayed(Duration(milliseconds: delayMs.toInt()));
      }
    }
  }

  static bool _isNetworkError(Object e) {
    if (e is TimeoutException) return true;
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('network-request-failed') ||
        str.contains('unavailable') ||
        str.contains('deadline-exceeded') ||
        str.contains('clientexception') ||
        str.contains('connection closed') ||
        str.contains('os error: 104')) {
      return true;
    }
    return false;
  }

  static AppError _mapToAppError(Object error, StackTrace? st) {
    if (error is AppError) return error;

    String msg = error.toString();
    ErrorCategory cat = ErrorCategory.unknown;

    if (error is TimeoutException) {
      cat = ErrorCategory.network;
      msg =
          'So‘rov vaqti tugadi (Timeout). Iltimos internetingizni tekshiring.';
    } else if (_isNetworkError(error)) {
      cat = ErrorCategory.network;
      msg = 'Tarmoqqa ulanib bo‘lmadi. Internet aloqasini tekshiring.';
    } else if (error is FirebaseException) {
      if (error.code.contains('auth')) {
        cat = ErrorCategory.auth;
        msg = 'Avtorizatsiya xatosi: ${error.message}';
      } else if (error.code == 'permission-denied') {
        cat = ErrorCategory.auth;
        msg = 'Sizda bu amalni bajarish uchun ruxsat yo‘q.';
      } else {
        msg = 'Server xatosi: ${error.message}';
      }
    } else if (error is FormatException) {
      cat = ErrorCategory.validation;
      msg = 'Ma\'lumotlar formati noto‘g‘ri.';
    }

    return AppError(msg, category: cat, originalError: error, stackTrace: st);
  }
}
