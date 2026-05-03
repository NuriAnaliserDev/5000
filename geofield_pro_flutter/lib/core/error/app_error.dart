enum ErrorCategory { network, auth, validation, permission, quota, unknown }

enum ErrorSeverity { low, medium, critical }

class AppError implements Exception {
  final String userMessage;
  final String? devMessage;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final Object? originalError;
  final StackTrace? stackTrace;

  AppError(
    this.userMessage, {
    this.devMessage,
    this.category = ErrorCategory.unknown,
    this.severity = ErrorSeverity.medium,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      'AppError[$category|$severity]: $userMessage ${devMessage != null ? "($devMessage)" : ""}';
}
