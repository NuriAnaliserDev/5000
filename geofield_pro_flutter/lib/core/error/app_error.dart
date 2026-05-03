enum ErrorCategory { network, auth, validation, unknown }

class AppError implements Exception {
  final String message;
  final ErrorCategory category;
  final Object? originalError;
  final StackTrace? stackTrace;

  AppError(
    this.message, {
    this.category = ErrorCategory.unknown,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError[$category]: $message';
}
