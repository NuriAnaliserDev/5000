import 'package:flutter/material.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = _colors(context, type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: colors,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white70,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.warning);

  static Color _colors(BuildContext context, SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green.shade700;
      case SnackbarType.error:
        return Colors.red.shade700;
      case SnackbarType.warning:
        return Colors.orange.shade700;
      case SnackbarType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

enum SnackbarType { info, success, error, warning }
