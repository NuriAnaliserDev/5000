import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/core/network/network_executor.dart';
import 'package:geofield_pro_flutter/core/error/app_error.dart';

void main() {
  group('NetworkExecutor', () {
    // ──────────────────────────────────────────────────
    // SUCCESS cases
    // ──────────────────────────────────────────────────
    test('returns value immediately when action succeeds on first try',
        () async {
      final result = await NetworkExecutor.execute(
        () async => 42,
        actionName: 'test_immediate_success',
      );
      expect(result, equals(42));
    });

    test('returns value after transient network error + retry', () async {
      int callCount = 0;
      final result = await NetworkExecutor.execute<String>(
        () async {
          callCount++;
          if (callCount < 2) throw Exception('socketexception');
          return 'success';
        },
        maxRetries: 3,
        baseDelayMs: 1,
        actionName: 'test_retry_success',
      );
      expect(result, equals('success'));
      expect(callCount, equals(2));
    });

    // ──────────────────────────────────────────────────
    // FAILURE + ERROR MAPPING cases
    // ──────────────────────────────────────────────────
    test('throws AppError after exhausting all retries', () async {
      int callCount = 0;
      await expectLater(
        () => NetworkExecutor.execute<void>(
          () async {
            callCount++;
            throw Exception('network-request-failed');
          },
          maxRetries: 2,
          baseDelayMs: 1,
          actionName: 'test_exhaust_retries',
        ),
        throwsA(isA<AppError>()),
      );
      // 1 initial + 2 retries
      expect(callCount, equals(3));
    });

    test('maps TimeoutException to network AppError', () async {
      await expectLater(
        () => NetworkExecutor.execute<void>(
          () => Future.delayed(
            const Duration(seconds: 60),
            () => null,
          ),
          maxRetries: 0,
          timeout: const Duration(milliseconds: 10),
          actionName: 'test_timeout',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.category,
          'category',
          ErrorCategory.network,
        )),
      );
    });

    test('does not retry when shouldRetry returns false', () async {
      int callCount = 0;
      await expectLater(
        () => NetworkExecutor.execute<void>(
          () async {
            callCount++;
            throw Exception('non-retryable business logic error');
          },
          maxRetries: 5,
          baseDelayMs: 1,
          shouldRetry: (_) => false,
          actionName: 'test_no_retry',
        ),
        throwsA(isA<AppError>()),
      );
      expect(callCount, equals(1));
    });

    test('passes through existing AppError without double-wrapping', () async {
      final original = AppError('already mapped', category: ErrorCategory.auth);
      AppError? caught;
      try {
        await NetworkExecutor.execute<void>(
          () async => throw original,
          maxRetries: 0,
          baseDelayMs: 1,
          shouldRetry: (_) => false,
          actionName: 'test_passthrough',
        );
      } on AppError catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      expect(caught!.userMessage, equals('already mapped'));
      expect(caught.category, equals(ErrorCategory.auth));
    });

    test('maps FormatException to validation category', () async {
      AppError? caught;
      try {
        await NetworkExecutor.execute<void>(
          () async => throw const FormatException('bad json'),
          maxRetries: 0,
          baseDelayMs: 1,
          shouldRetry: (_) => false,
          actionName: 'test_format',
        );
      } on AppError catch (e) {
        caught = e;
      }
      expect(caught?.category, equals(ErrorCategory.validation));
    });
  });
}
