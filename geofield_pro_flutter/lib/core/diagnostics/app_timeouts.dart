/// Barcha vaqt chegaralari bitta joyda — debug va stress testda qiymatni oson almashtirish uchun.
abstract final class AppTimeouts {
  static const Duration splashAuthStateFirstEvent = Duration(seconds: 8);
  static const Duration splashFirestoreOnboardingSync = Duration(seconds: 6);
  static const Duration cameraInitPerPresetAttempt = Duration(seconds: 22);
  /// Geolocator `isLocationServiceEnabled` / permission tekshiruvlari.
  static const Duration locationServiceProbe = Duration(seconds: 10);
  static const Duration gpsPermissionProbe = Duration(seconds: 10);
  /// `getCurrentPosition` tashqi cheklov (ichki LocationSettings dan mustaqil).
  static const Duration getCurrentPositionOuter = Duration(seconds: 14);

  /// `Position.timestamp` juda eski bo‘lsa, qabul qilinmasin (OS kesh / qayta ishlatilgan fix).
  static const Duration gpsFixMaxAge = Duration(minutes: 2);

  /// `GpsBroadcaster` Geolocator oqimi xatosi keyin qayta ulanish kechikishi.
  static const Duration gpsStreamRecoverDelay = Duration(seconds: 3);

  /// `HiveDb.init()` — butun bootstrapda qotib qolmaslik uchun.
  static const Duration hiveBootstrapInit = Duration(seconds: 90);

  /// `sync_queue` kompakt qilish (katta navbatdan keyin).
  static const Duration hiveCompactAfterSync = Duration(seconds: 15);

  /// GIS ZIP yozish + (ixtiyoriy) ulashish pipeline.
  static const Duration gisExportPipeline = Duration(seconds: 90);
}