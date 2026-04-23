import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';

import 'app/app_providers.dart';
import 'app/geo_field_pro_app.dart';
import 'firebase_options.dart';
import 'services/hive_db.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        debugPrint('Firebase initialized successfully.');
      }
    } catch (e) {
      debugPrint('CRITICAL: Firebase initialization failed: $e');
      if (!kIsWeb) rethrow;
    }
    await HiveDb.init();
    if (!kIsWeb) {
      await FMTCObjectBoxBackend().initialise();
      await FMTCStore('opentopomap').manage.create();
      await FMTCStore('osm').manage.create();
      await FMTCStore('satellite').manage.create();
    }
  } catch (e, stack) {
    debugPrint('CRITICAL INITIALIZATION ERROR: $e');
    debugPrint(stack.toString());
  }
  runApp(
    MultiProvider(
      providers: buildAppChangeNotifierProviders(),
      child: const GeoFieldProApp(),
    ),
  );
}
