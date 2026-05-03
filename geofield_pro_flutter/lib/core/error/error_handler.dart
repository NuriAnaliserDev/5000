import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../snackbar_helper.dart';
import 'app_error.dart';
import 'error_logger.dart';

class ErrorHandler {
  static AppError process(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    String msg = error.toString();
    ErrorCategory cat = ErrorCategory.unknown;

    if (error is FirebaseException) {
      if (error.code == 'user-not-found') {
        cat = ErrorCategory.auth;
        msg =
            'Bunday foydalanuvchi topilmadi yoki email ro\'yxatdan o\'tmagan.';
      } else if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        cat = ErrorCategory.auth;
        msg = 'Email yoki parol xato.';
      } else if (error.code == 'email-already-in-use') {
        cat = ErrorCategory.auth;
        msg = 'Bu email allaqachon ro\'yxatdan o\'tgan.';
      } else if (error.code == 'weak-password') {
        cat = ErrorCategory.validation;
        msg = 'Parol juda zaif (kamida 6 belgi bo\'lishi kerak).';
      } else if (error.code == 'too-many-requests') {
        cat = ErrorCategory.network;
        msg = 'Juda ko\'p urinish. Bir oz kuting.';
      } else if (error.code == 'network-request-failed' ||
          error.code == 'unavailable') {
        cat = ErrorCategory.network;
        msg = 'Internetga ulanishda xatolik.';
      } else if (error.code.contains('auth') ||
          error.code == 'unauthenticated') {
        cat = ErrorCategory.auth;
        msg = 'Avtorizatsiya xatosi: ${error.message}';
      } else if (error.code == 'permission-denied') {
        cat = ErrorCategory.auth;
        msg = 'Sizda bu amalni bajarish uchun ruxsat yo‘q.';
      } else if (error.code == 'resource-exhausted') {
        cat = ErrorCategory.network;
        msg = 'Kvota tugadi yoki tizim vaqtincha band (resource-exhausted).';
      } else {
        msg = error.message ?? error.toString();
      }
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('ClientException')) {
      cat = ErrorCategory.network;
      msg = 'Tarmoqqa ulanib bo‘lmadi.';
    } else if (error is FormatException) {
      cat = ErrorCategory.validation;
      msg = 'Ma\'lumotlar formati noto‘g‘ri.';
    }

    final appError = AppError(msg,
        category: cat, originalError: error, stackTrace: stackTrace);
    ErrorLogger.log(appError);
    return appError;
  }

  static void show(BuildContext context, Object error,
      [StackTrace? stackTrace]) {
    final appError = process(error, stackTrace);
    SnackbarHelper.show(context, appError.message, type: SnackbarType.error);
  }
}
