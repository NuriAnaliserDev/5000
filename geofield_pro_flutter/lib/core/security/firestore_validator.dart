class FirestoreValidator {
  FirestoreValidator._();

  /// Validates a string to ensure it is not null, not empty (optional), and within a maximum length.
  static bool isValidString(String? value,
      {bool allowEmpty = false, int maxLength = 2500}) {
    if (value == null) return false;
    if (!allowEmpty && value.trim().isEmpty) return false;
    if (value.length > maxLength) return false;
    return true;
  }

  /// Validates numbers to ensure they are within an acceptable range.
  static bool isValidNumber(num? value,
      {num min = -9999999, num max = 9999999}) {
    if (value == null) return false;
    if (value < min || value > max) return false;
    return true;
  }

  /// Deeply inspects a map before sending to Firestore to catch massive payloads or invalid data.
  static void validatePayload(Map<String, dynamic> data) {
    if (data.length > 100) {
      throw const FormatException(
          'Payload contains too many keys, risk of large document.');
    }
    data.forEach((key, value) {
      if (value is String) {
        if (value.length > 10000) {
          throw FormatException(
              'Field $key exceeds maximum allowed string length (10000 chars).');
        }
      }
      if (value is List) {
        if (value.length > 1000) {
          throw FormatException('Field $key contains too many list items.');
        }
      }
      // Recursively validate nested maps
      if (value is Map<String, dynamic>) {
        validatePayload(value);
      }
    });
  }
}
