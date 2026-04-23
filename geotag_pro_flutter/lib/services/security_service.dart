import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _pinKey = 'user_pin_code';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  /// Checks if the device supports biometric authentication
  Future<bool> isBiometricsAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Triggers biometric authentication (FaceID/Fingerprint)
  Future<bool> authenticateBiometrically() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'GeoField Pro ma\'lumotlarini himoya qilish uchun autentifikatsiyadan o\'ting',
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Saves a new PIN code securely
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Verifies the provided PIN against the stored one
  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  /// Checks if a PIN has been set
  Future<bool> hasPin() async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin != null && storedPin.isNotEmpty;
  }

  /// Enables or disables biometrics preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }

  /// Checks if biometrics are enabled by user preference
  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _biometricsEnabledKey);
    return value == 'true';
  }
}
