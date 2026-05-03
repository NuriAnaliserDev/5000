import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../error/app_error.dart';
import '../error/error_mapper.dart';
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

  static bool isNetworkError(Object e) {
    if (e is TimeoutException) return true;

    // Explicitly reject Firebase permission and quota errors from retry logic
    if (e is FirebaseException) {
      if (e.code == 'permission-denied' || e.code == 'resource-exhausted') {
        return false;
      }
    }

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

  // Internal alias for backwards compat
  static bool _isNetworkError(Object e) => isNetworkError(e);

  static AppError _mapToAppError(Object error, StackTrace? st) {
    return ErrorMapper.map(error, st);
  }
}
