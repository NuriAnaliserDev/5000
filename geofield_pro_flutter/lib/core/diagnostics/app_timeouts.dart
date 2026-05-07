/// Barcha vaqt chegaralari bitta joyda — debug va stress testda qiymatni oson almashtirish uchun.
abstract final class AppTimeouts {
  static const Duration splashAuthStateFirstEvent = Duration(seconds: 8);
  static const Duration splashFirestoreOnboardingSync = Duration(seconds: 6);
  static const Duration cameraInitPerPresetAttempt = Duration(seconds: 22);
}
