import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/smart_camera/smart_camera_screen.dart';
import 'screens/global_map_screen.dart';
import 'screens/station_summary_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/scale_assistant_screen.dart';
import 'screens/image_painter_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/auto_table_review_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/hive_db.dart';
import 'services/settings_controller.dart';
import 'services/station_repository.dart';
import 'services/theme_controller.dart';
import 'services/track_service.dart';
import 'services/location_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/chat_repository.dart';
import 'services/boundary_service.dart';
import 'services/auth_service.dart';
import 'services/mine_report_repository.dart';
import 'services/security_provider.dart';
import 'services/geological_line_repository.dart';
import 'services/presence_service.dart';
import 'services/sos_service.dart';
import 'screens/auth_screen.dart';
import 'utils/security_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/web/web_dashboard_main.dart';
import 'screens/web/web_login_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      debugPrint('CRITICAL: Firebase initialization failed: $e');
      // On web this is sometimes normal if options are missing, but on mobile it's fatal.
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
    // In a real app, you might want to show a global error screen
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CloudSyncService>(
          create: (ctx) {
            final service = CloudSyncService();
            service.init();
            return service;
          },
        ),
        ChangeNotifierProxyProvider<CloudSyncService, StationRepository>(
          create: (ctx) => StationRepository(Provider.of<CloudSyncService>(ctx, listen: false)),
          update: (_, sync, prev) => prev ?? StationRepository(sync),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(),
        ),
        ChangeNotifierProxyProvider<SettingsController, ChatRepository>(
          create: (ctx) => ChatRepository(settingsController: Provider.of<SettingsController>(ctx, listen: false)),
          update: (_, settings, chatRepo) => chatRepo ?? ChatRepository(settingsController: settings),
        ),
        ChangeNotifierProxyProvider<CloudSyncService, TrackService>(
          create: (ctx) => TrackService(Provider.of<CloudSyncService>(ctx, listen: false)),
          update: (_, sync, prev) => prev ?? TrackService(sync),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider(
          create: (_) => BoundaryService(),
        ),
        ChangeNotifierProvider(
          create: (_) => MineReportRepository(),
        ),
        ChangeNotifierProvider<GeologicalLineRepository>(
          create: (_) {
            final repo = GeologicalLineRepository();
            repo.init(); // async init — lines load in background
            return repo;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SecurityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PresenceService(),
        ),
        ChangeNotifierProvider(
          create: (_) => SosService(),
        ),
      ],
      child: const GeoFieldProApp(),
    ),
  );
}


class GeoFieldProApp extends StatelessWidget {
  const GeoFieldProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeCtrl, _) {
        return MaterialApp(
          title: 'GeoField Pro N',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF263238),
              secondary: Color(0xFF1565C0), 
              surface: Color(0xFFFFFFFF),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              foregroundColor: Color(0xFF263238),
              elevation: 0,
            ),
            textTheme: GoogleFonts.robotoTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF455A64),
              secondary: Color(0xFF42A5F5),
              surface: Color(0xFF121212),
            ),
            textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          themeMode: themeCtrl.mode,
          builder: (context, child) {
            return SecurityWrapper(child: child!);
          },
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                if (kIsWeb) {
                  return MaterialPageRoute(builder: (context) {
                    final auth = context.watch<AuthService>();
                    return auth.isAuthenticated ? const WebDashboardMain() : const WebLoginScreen();
                  });
                }
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case '/dashboard':
                return MaterialPageRoute(builder: (_) => const DashboardScreen());
              case '/onboarding':
                return MaterialPageRoute(builder: (_) => const OnboardingScreen());
              case '/auth':
                return MaterialPageRoute(builder: (_) => AuthScreen());
              case '/messages':
                return MaterialPageRoute(builder: (_) => const MessagesScreen());
              case '/chat':
                final groupId = settings.arguments as String;
                return MaterialPageRoute(builder: (_) => ChatScreen(groupId: groupId));
              case '/auto-table-review':
                final path = settings.arguments as String;
                return MaterialPageRoute(builder: (_) => AutoTableReviewScreen(imagePath: path));
              case '/camera':
                final stationId = settings.arguments as int?;
                return MaterialPageRoute(
                  builder: (_) => SmartCameraScreen(stationId: stationId),
                );
              case '/map':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(builder: (_) => GlobalMapScreen(initLocation: args));
              case '/archive':
                return MaterialPageRoute(builder: (_) => const ArchiveScreen());
              case '/analysis':
                return MaterialPageRoute(builder: (_) => const AnalysisScreen());
              case '/admin':
              case '/settings':
                return MaterialPageRoute(builder: (_) => const AdminScreen());
              case '/scale-assistant':
                return MaterialPageRoute(builder: (_) => const ScaleAssistantScreen());
              case '/painter':
                final path = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ImagePainterScreen(imagePath: path),
                );
              case '/station':
                final id = settings.arguments as int?;
                return MaterialPageRoute(
                  builder: (_) => StationSummaryScreen(stationId: id),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Route not found')),
                  ),
                );
            }
          },
        );
      },
    );
  }
}

