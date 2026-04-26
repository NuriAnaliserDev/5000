import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/services/security/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('hash har safar turli salt bilan farq qiladi', () {
      final a = PinHasher.hashPin('123456');
      final b = PinHasher.hashPin('123456');
      expect(a, isNot(equals(b)));
      expect(a.startsWith('v1:'), isTrue);
    });

    test('to‘g‘ri PIN tekshiruvdan o‘tadi', () {
      final stored = PinHasher.hashPin('1234');
      expect(PinHasher.verify('1234', stored), isTrue);
    });

    test('noto‘g‘ri PIN rad etiladi', () {
      final stored = PinHasher.hashPin('1234');
      expect(PinHasher.verify('0000', stored), isFalse);
      expect(PinHasher.verify('12345', stored), isFalse);
    });

    test('legacy plain PIN — teng bo‘lsa o‘tadi, bo‘lmasa — rad', () {
      const legacy = '5678';
      expect(PinHasher.isLegacy(legacy), isTrue);
      expect(PinHasher.verify('5678', legacy), isTrue);
      expect(PinHasher.verify('5679', legacy), isFalse);
    });

    test('hash formati barqaror (v1:salt:iter:hash)', () {
      final h = PinHasher.hashPin('pin');
      final parts = h.split(':');
      expect(parts.length, 4);
      expect(parts[0], 'v1');
      expect(int.parse(parts[2]), greaterThan(10000));
    });
  });
}
