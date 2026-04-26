import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/screens/error_screen.dart';

void main() {
  testWidgets('ErrorScreen tugmalar', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorScreen(
          message: 'test xato',
          onRetry: () => retried = true,
        ),
      ),
    );
    expect(find.text('Ishga tushirish xatosi'), findsOneWidget);
    await tester.tap(find.text('Qayta urinish'));
    expect(retried, isTrue);
  });
}
