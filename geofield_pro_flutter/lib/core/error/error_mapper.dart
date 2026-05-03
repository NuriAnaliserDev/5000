import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'app_error.dart';

class ErrorMapper {
  static AppError map(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }

    String userMessage = 'Noma\'lum xatolik yuz berdi.';
    String devMessage = error.toString();
    ErrorCategory category = ErrorCategory.unknown;
    ErrorSeverity severity = ErrorSeverity.medium;

    if (error is TimeoutException) {
      category = ErrorCategory.network;
      severity = ErrorSeverity.low; // Can just be retried
      userMessage =
          'So‘rov vaqti tugadi (Timeout). Iltimos, internetingizni tekshiring.';
    } else if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        category = ErrorCategory.permission;
        severity = ErrorSeverity.medium;
        userMessage = 'Sizda bu amalni bajarish uchun ruxsat yo‘q.';
      } else if (error.code == 'resource-exhausted') {
        category = ErrorCategory.quota;
        severity = ErrorSeverity.medium;
        userMessage =
            'Kvota tugadi yoki tizim vaqtincha band (resource-exhausted).';
      } else if (error.code == 'user-not-found' ||
          error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        category = ErrorCategory.auth;
        severity = ErrorSeverity.low;
        userMessage = 'Email yoki parol xato.';
      } else if (error.code == 'email-already-in-use') {
        category = ErrorCategory.auth;
        severity = ErrorSeverity.low;
        userMessage = 'Bu email allaqachon ro\'yxatdan o\'tgan.';
      } else if (error.code == 'network-request-failed' ||
          error.code == 'unavailable') {
        category = ErrorCategory.network;
        severity = ErrorSeverity.low;
        userMessage = 'Tarmoqqa ulanishda xatolik yuz berdi.';
      } else {
        category = ErrorCategory.unknown;
        severity = ErrorSeverity.medium;
        userMessage = 'Server xatosi yuz berdi: ${error.message}';
      }
    } else if (error is FormatException) {
      category = ErrorCategory.validation;
      severity = ErrorSeverity.low;
      userMessage = 'Ma\'lumotlar formati noto‘g‘ri kiritildi.';
    } else {
      final str = error.toString().toLowerCase();
      if (str.contains('socketexception') ||
          str.contains('clientexception') ||
          str.contains('handshakeexception')) {
        category = ErrorCategory.network;
        severity = ErrorSeverity.low;
        userMessage =
            'Tarmoqqa ulanib bo‘lmadi. Internet aloqasini tekshiring.';
      }
    }

    return AppError(
      userMessage,
      devMessage: devMessage,
      category: category,
      severity: severity,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
