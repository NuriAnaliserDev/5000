import 'package:flutter/material.dart';
import '../snackbar_helper.dart';
import 'app_error.dart';
import 'error_logger.dart';

class ErrorHandler {
  static void show(BuildContext context, AppError appError) {
    // Log before showing
    ErrorLogger.log(appError);

    // CRITICAL: Blocking dialog
    if (appError.severity == ErrorSeverity.critical) {
      _showErrorDialog(
        context,
        title: 'Kritik Xatolik',
        message: appError.userMessage,
        isDismissible: false,
      );
      return;
    }

    // Deterministic Category Mapping
    switch (appError.category) {
      case ErrorCategory.network:
        SnackbarHelper.show(context, appError.userMessage,
            type: SnackbarType.error);
        break;
      case ErrorCategory.validation:
        SnackbarHelper.show(context, appError.userMessage,
            type: SnackbarType.warning);
        break;
      case ErrorCategory.permission:
        _showErrorDialog(context,
            title: 'Ruxsat etilmagan', message: appError.userMessage);
        break;
      case ErrorCategory.quota:
        _showErrorDialog(context,
            title: 'Limit tugadi', message: appError.userMessage);
        break;
      case ErrorCategory.auth:
        SnackbarHelper.show(context, appError.userMessage,
            type: SnackbarType.error);
        break;
      case ErrorCategory.unknown:
        _showErrorDialog(context, title: 'Xatolik', message: appError.userMessage);
        break;
    }
  }

  static void _showErrorDialog(BuildContext context,
      {required String title,
      required String message,
      bool isDismissible = true}) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tushunarli'),
          ),
        ],
      ),
    );
  }
}
