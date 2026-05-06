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
import '../core/error/error_logger.dart';
import '../core/network/network_executor.dart';
import '../core/di/dependency_injection.dart';
import '../core/diagnostics/diagnostic_service.dart';

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
    await DiagnosticService.instance.init();
    setupDependencies();
  } catch (e, st) {
    ErrorLogger.record(e, st,
        customMessage: 'WidgetsFlutterBinding ishga tushmadi');
    return AppBootstrapFailure(
      'WidgetsFlutterBinding ishga tushmadi: $e',
      e,
      st,
    );
  }

  var firebaseOk = false;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final firebaseConfigured = options.projectId.isNotEmpty &&
        options.appId.isNotEmpty &&
        options.apiKey.isNotEmpty;

    if (!firebaseConfigured) {
      if (kDebugMode) {
        debugPrint(
          'Firebase o‘tkazib yuborildi: konfiguratsiya bo‘sh '
          '(flutterfire configure yoki --dart-define). Mahalliy rejim.',
        );
      }
    } else {
      await Firebase.initializeApp(options: options);
      // ignore: deprecated_member_use
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider: AppleProvider.deviceCheck,
        // ignore: deprecated_member_use
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
      firebaseOk = true;
      if (kDebugMode) {
        debugPrint('Firebase initialized successfully.');
      }
    }
  } catch (e, st) {
    ErrorLogger.record(e, st, customMessage: 'Firebase initialization failed');
    if (!kIsWeb) {
      debugPrint(
          'Mobil: Firebase yo‘q — mahalliy rejim (bulut/sinxron cheklangan).');
    }
  }

  try {
    await HiveDb.init();
  } catch (e, st) {
    ErrorLogger.record(e, st,
        customMessage: 'Mahalliy ma\'lumotlar bazasi (Hive) ochilmadi');
    return AppBootstrapFailure(
      'Mahalliy ma\'lumotlar bazasi (Hive) ochilmadi. Ilova sizsiz dala ma\'lumotlarini saqlay olmaydi.\n$e',
      e,
      st,
    );
  }

  if (!kIsWeb) {
    Object? fmtcErr;
    try {
      await NetworkExecutor.execute(
        () async {
          await FMTCObjectBoxBackend().initialise();
          await FMTCStore('opentopomap').manage.create();
          await FMTCStore('osm').manage.create();
          await FMTCStore('satellite').manage.create();
        },
        maxRetries: 2,
        baseDelayMs: 400,
        timeout: const Duration(seconds: 15),
        actionName: 'FMTC Offline Map Init',
        shouldRetry: (_) => true, // Always retry init on error
      );
    } catch (e, st) {
      fmtcErr = e;
      ErrorLogger.record(e, st,
          customMessage: 'FMTC oflayn xarita keshi ishga tushmadi');
    }
    if (fmtcErr != null) {
      debugPrint('WARN: Oflayn xarita keshi xatosi yuz berdi: $fmtcErr');
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
