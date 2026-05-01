import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geofield_pro_flutter/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SecurityService (mock secure storage)', () {
    test('savePin bo‘sh — kalit o‘chiriladi, hasPin false', () async {
      final svc = SecurityService();
      await svc.savePin('1234');
      expect(await svc.hasPin(), isTrue);
      await svc.savePin('');
      expect(await svc.hasPin(), isFalse);
    });

    test('clearPin — hasPin false va verifyPin rad', () async {
      final svc = SecurityService();
      await svc.savePin('9999');
      expect(await svc.hasPin(), isTrue);
      await svc.clearPin();
      expect(await svc.hasPin(), isFalse);
      expect(await svc.verifyPin('9999'), isFalse);
    });

    test('verifyPin muvaffaqiyatli — hasPin barqaror', () async {
      final svc = SecurityService();
      await svc.savePin('4321');
      expect(await svc.verifyPin('4321'), isTrue);
      expect(await svc.hasPin(), isTrue);
    });
  });
}
