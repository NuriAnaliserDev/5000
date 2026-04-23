import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'security/pin_hasher.dart';

/// Xavfsizlik xizmati — PIN + biometriya.
///
/// PIN hech qachon ochiq matn sifatida saqlanmaydi. Saqlanadigan qiymat:
/// `v1:<salt>:<iter>:<pbkdf2-sha256>` (qarang: [PinHasher]).
///
/// Eski ochiq PIN'lar birinchi muvaffaqiyatli `verifyPin` paytida avtomatik
/// ravishda yangi formatga o‘tkaziladi (migration-safe).
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _pinKey = 'user_pin_code';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  Future<bool> isBiometricsAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    return canCheck || await _auth.isDeviceSupported();
  }

  Future<bool> authenticateBiometrically() async {
    try {
      return await _auth.authenticate(
        localizedReason:
            'GeoField Pro ma\'lumotlarini himoya qilish uchun autentifikatsiyadan o\'ting',
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Yangi PIN saqlash. Har doim hashlanadi (PBKDF2-SHA256, 100k iter).
  Future<void> savePin(String pin) async {
    final hashed = PinHasher.hashPin(pin);
    await _storage.write(key: _pinKey, value: hashed);
  }

  /// PIN tekshirish. Agar saqlangan qiymat legacy (ochiq) bo‘lsa, muvaffaqiyatli
  /// tekshiruvda avtomatik ravishda yangi formatga ko‘chiriladi.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null || stored.isEmpty) return false;

    final ok = PinHasher.verify(pin, stored);
    if (ok && PinHasher.isLegacy(stored)) {
      await savePin(pin); // migratsiya
    }
    return ok;
  }

  Future<bool> hasPin() async {
    final s = await _storage.read(key: _pinKey);
    return s != null && s.isNotEmpty;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricsEnabled() async {
    final v = await _storage.read(key: _biometricsEnabledKey);
    return v == 'true';
  }
}
