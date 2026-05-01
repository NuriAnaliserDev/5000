import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/l10n/app_strings.dart';
import 'package:geofield_pro_flutter/services/hive_db.dart';
import 'package:geofield_pro_flutter/services/settings_controller.dart';
import 'package:geofield_pro_flutter/utils/app_nav_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late SettingsController settings;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('nav_bar_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveDb.settingsBox);
    await Hive.box<dynamic>(HiveDb.settingsBox).put('expertMode', false);
    settings = SettingsController();
  });

  tearDown(() async {
    await Hive.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  testWidgets('5 ta yorliq + Yana; expert bo‘lmasa Scale matni pastki panda yo‘q',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: GeoFieldStrings.localizationsDelegates,
          supportedLocales: GeoFieldStrings.supportedLocales,
          locale: const Locale('uz'),
          home: const Scaffold(
            body: Placeholder(),
            bottomNavigationBar: AppBottomNavBar(activeRoute: '/map'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final uz = lookupGeoFieldStrings(const Locale('uz'));
    expect(find.text(uz.dashboard), findsOneWidget);
    expect(find.text(uz.map), findsOneWidget);
    expect(find.text(uz.camera), findsOneWidget);
    expect(find.text(uz.archive), findsOneWidget);
    expect(find.text(uz.nav_more), findsOneWidget);
    expect(find.text(uz.scale_short), findsNothing);
  });

  testWidgets('useShellNavigation: tab bosilganda push o‘rniga callback',
      (tester) async {
    String? tappedRoute;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: GeoFieldStrings.localizationsDelegates,
          supportedLocales: GeoFieldStrings.supportedLocales,
          locale: const Locale('uz'),
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              activeRoute: '/dashboard',
              useShellNavigation: true,
              onShellTabSelected: (r) => tappedRoute = r,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pumpAndSettle();
    expect(tappedRoute, '/map');
  });
}
