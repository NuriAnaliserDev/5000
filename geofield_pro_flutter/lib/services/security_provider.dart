import 'package:flutter/material.dart';
import 'security_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityService _service = SecurityService();

  bool _isLocked = false;
  bool _isBioSupported = false;
  bool _isBioEnabled = false;
  bool _hasPin = false;

  bool get isLocked => _isLocked;
  bool get isBioSupported => _isBioSupported;
  bool get isBioEnabled => _isBioEnabled;
  bool get hasPin => _hasPin;

  SecurityProvider() {
    _init();
  }

  Future<void> _init() async {
    _isBioSupported = await _service.isBiometricsAvailable();
    _isBioEnabled = await _service.isBiometricsEnabled();
    _hasPin = await _service.hasPin();
    // If PIN is enabled, we start locked (on app cold start)
    if (_hasPin) {
      _isLocked = true;
    }
    notifyListeners();
  }

  /// Locks the app
  void lock() {
    if (_hasPin) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Unlocks the app using either Biometrics or PIN
  Future<bool> unlockWithBiometrics() async {
    if (!_isBioSupported || !_isBioEnabled) return false;
    
    final success = await _service.authenticateBiometrically();
    if (success) {
      _isLocked = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> unlockWithPin(String pin) async {
    final success = await _service.verifyPin(pin);
    if (success) {
      _isLocked = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> enableSecurity(String pin, bool useBio) async {
    await _service.savePin(pin);
    await _service.setBiometricsEnabled(useBio);
    _hasPin = true;
    _isBioEnabled = useBio;
    notifyListeners();
  }

  Future<void> disableSecurity() async {
    await _service.clearPin();
    await _service.setBiometricsEnabled(false);
    _hasPin = false;
    _isBioEnabled = false;
    _isLocked = false;
    notifyListeners();
  }

  /// Forces a refresh of availability (e.g. after changing OS settings)
  Future<void> refreshStatus() async {
    _isBioSupported = await _service.isBiometricsAvailable();
    _isBioEnabled = await _service.isBiometricsEnabled();
    _hasPin = await _service.hasPin();
    notifyListeners();
  }
}
