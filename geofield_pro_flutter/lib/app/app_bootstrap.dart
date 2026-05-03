import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'app_providers.dart';
import 'geo_field_pro_app.dart';
import '../firebase_options.dart';
import '../services/hive_db.dart';
import '../utils/firebase_ready.dart';

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

/// Ilova o‘rnatilishi: Firebase (ixtiyoriy, xato qilganda mahalliy rejim) → majburiy Hive
/// → (mobil) oflayn xarita keshi (xato bo‘lsa ogohlantirish).
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

  var firebaseOk = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
    firebaseOk = true;
    if (kDebugMode) {
      debugPrint('Firebase initialized successfully.');
    }
  } catch (e) {
    debugPrint('WARN: Firebase initialization failed: $e');
    if (!kIsWeb) {
      debugPrint(
        'Mobil: Firebase yo‘q — mahalliy rejim (bulut/sinxron cheklangan).',
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
    Object? fmtcErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        await FMTCObjectBoxBackend().initialise();
        await FMTCStore('opentopomap').manage.create();
        await FMTCStore('osm').manage.create();
        await FMTCStore('satellite').manage.create();
        fmtcErr = null;
        break;
      } catch (e) {
        fmtcErr = e;
      }
    }
    if (fmtcErr != null) {
      debugPrint(
        'WARN: oflayn xarita keshi (FMTC) ishga tushmadi: $fmtcErr. Xarita to‘liq oflayn ishlashidan mahrum bo‘lishi mumkin.',
      );
    }
  }

  return AppBootstrapSuccess(
    MultiProvider(
      providers: [
        Provider<FirebaseBootstrapState>.value(
          value: FirebaseBootstrapState(isCloudEnabled: firebaseOk),
        ),
        ...buildAppChangeNotifierProviders(),
      ],
      child: const GeoFieldProApp(),
    ),
  );
}
