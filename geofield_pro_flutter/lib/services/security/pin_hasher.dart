import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 asosida PIN hashlash.
///
/// Format (salt ham ichida): `v1:<salt_b64>:<iter>:<hash_b64>`.
/// Bitta string sifatida `FlutterSecureStorage`da saqlanadi.
class PinHasher {
  static const int _iterations = 100000;
  static const int _saltLen = 16;
  static const int _keyLen = 32;

  static String hashPin(String pin, {String? saltB64}) {
    final salt =
        saltB64 != null ? base64Decode(saltB64) : _randomBytes(_saltLen);
    final key = _pbkdf2(utf8.encode(pin), salt, _iterations, _keyLen);
    return 'v1:${base64Encode(salt)}:$_iterations:${base64Encode(key)}';
  }

  /// `true` bo‘lsa pin to‘g‘ri. [stored] — `v1:...:...:...` string.
  static bool verify(String pin, String stored) {
    final parts = stored.split(':');
    if (parts.length != 4 || parts.first != 'v1') {
      // Eski plain PIN — to‘g‘ridan to‘g‘ri solishtirish.
      return pin == stored;
    }
    final saltB64 = parts[1];
    final iter = int.tryParse(parts[2]) ?? _iterations;
    final expected = parts[3];
    final key = _pbkdf2(utf8.encode(pin), base64Decode(saltB64), iter, _keyLen);
    final hashB64 = base64Encode(key);
    return _constEq(hashB64, expected);
  }

  /// Eski plain PIN'ni yangi hash formatiga aylantirish lozim yoki yo‘qligi.
  static bool isLegacy(String stored) => !stored.startsWith('v1:');

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLen,
  ) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLen / 32).ceil();
    final out = BytesBuilder();
    for (var i = 1; i <= blocks; i++) {
      final block = _deriveBlock(hmac, salt, iterations, i);
      out.add(block);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, keyLen));
  }

  static Uint8List _deriveBlock(
    Hmac hmac,
    List<int> salt,
    int iterations,
    int index,
  ) {
    final saltBlock = Uint8List(salt.length + 4);
    saltBlock.setRange(0, salt.length, salt);
    saltBlock[salt.length] = (index >> 24) & 0xff;
    saltBlock[salt.length + 1] = (index >> 16) & 0xff;
    saltBlock[salt.length + 2] = (index >> 8) & 0xff;
    saltBlock[salt.length + 3] = index & 0xff;

    var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    return t;
  }

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rnd.nextInt(256)));
  }

  /// Timing-safe equality (sekundlarda farqlanmasin).
  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
