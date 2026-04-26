import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Hive at-rest shifrlash uchun master kalit menejeri.
///
/// Kalit `flutter_secure_storage`da (Android Keystore / iOS Keychain) saqlanadi.
/// Birinchi chaqiruvda 256-bit kalit generatsiya qilinadi va shu kalitdan
/// [HiveAesCipher] yaratiladi.
class EncryptionManager {
  EncryptionManager._();

  static const String _masterKeyKey = 'hive_master_key_v1';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static HiveAesCipher? _cached;

  /// Shifrlash kalitini qaytaradi (kesh bilan). Har doim bitta instance.
  static Future<HiveAesCipher> cipher() async {
    if (_cached != null) return _cached!;
    final bytes = await _loadOrGenerate();
    _cached = HiveAesCipher(bytes);
    return _cached!;
  }

  static Future<List<int>> _loadOrGenerate() async {
    final existing = await _storage.read(key: _masterKeyKey);
    if (existing != null && existing.isNotEmpty) {
      try {
        return base64Decode(existing);
      } catch (_) {
        // buzilgan kalit — qayta generatsiya.
      }
    }
    final key = _randomKey();
    await _storage.write(key: _masterKeyKey, value: base64Encode(key));
    return key;
  }

  static List<int> _randomKey() {
    final rnd = Random.secure();
    return List<int>.generate(32, (_) => rnd.nextInt(256));
  }

  /// Test/rollback uchun: kalitni o‘chirish (ma'lumot yo‘qoladi!).
  static Future<void> eraseKey() async {
    _cached = null;
    await _storage.delete(key: _masterKeyKey);
  }
}
