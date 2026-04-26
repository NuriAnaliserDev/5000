import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'app_providers.dart';
import 'geo_field_pro_app.dart';
import '../firebase_options.dart';
import '../services/hive_db.dart';

/// Successful bootstrap: root widget (usually [MultiProvider] + [GeoFieldProApp]).
sealed class AppBootstrapResult {}

class AppBootstrapSuccess extends AppBootstrapResult {
  AppBootstrapSuccess(this.rootWidget);
  final Widget rootWidget;
}

class AppBootstrapFailure extends AppBootstrapResult {
  AppBootstrapFailure(this.userMessage, [this.cause, this.stackTrace]);
  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;
}

/// Ilova o‘rnatilishi: Firebase (platforma siyosati) → majburiy Hive → (mobil) oflayn
/// xarita keshi (xatolik xavfli, lekin ilova ochiladi).
Future<AppBootstrapResult> runAppBootstrap() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e, st) {
    return AppBootstrapFailure(
      'WidgetsFlutterBinding ishga tushmadi: $e',
      e,
      st,
    );
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('Firebase initialized successfully.');
    }
  } catch (e) {
    debugPrint('CRITICAL: Firebase initialization failed: $e');
    if (!kIsWeb) {
      return AppBootstrapFailure(
        'Firebase ishga tushmadi. Internet va google-services / Firebase sozlamalarini tekshiring.\n$e',
        e,
      );
    }
  }

  try {
    await HiveDb.init();
  } catch (e, st) {
    return AppBootstrapFailure(
      'Mahalliy ma\'lumotlar bazasi (Hive) ochilmadi. Ilova sizsiz dala ma\'lumotlarini saqlay olmaydi.\n$e',
      e,
      st,
    );
  }

  if (!kIsWeb) {
    try {
      await FMTCObjectBoxBackend().initialise();
      await FMTCStore('opentopomap').manage.create();
      await FMTCStore('osm').manage.create();
      await FMTCStore('satellite').manage.create();
    } catch (e) {
      debugPrint(
        'WARN: oflayn xarita keshi (FMTC) ishga tushmadi: $e. Xarita barcha joyda to‘liq oflayn ishlashidan mahrum bo‘lishi mumkin.',
      );
    }
  }

  return AppBootstrapSuccess(
    MultiProvider(
      providers: buildAppChangeNotifierProviders(),
      child: const GeoFieldProApp(),
    ),
  );
}
