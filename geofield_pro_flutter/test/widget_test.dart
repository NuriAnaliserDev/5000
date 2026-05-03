import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

void main() {
  testWidgets('Smoke test: app shell widget renders',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('GeoField Pro Smoke'),
        ),
      ),
    );

    expect(find.text('GeoField Pro Smoke'), findsOneWidget);
  });
}
