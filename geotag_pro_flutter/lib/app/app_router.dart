import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/archive_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/auto_table_review_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/global_map_screen.dart';
import '../screens/image_painter_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/scale_assistant_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/station_summary_screen.dart';
import '../screens/smart_camera/smart_camera_screen.dart';
import '../services/auth_service.dart';
import '../screens/web/web_dashboard_main.dart';
import '../screens/web/web_login_screen.dart';

/// Ilova marshrutlari — [main.dart] dan ajratilgan.
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String autoTableReview = '/auto-table-review';
  static const String camera = '/camera';
  static const String map = '/map';
  static const String archive = '/archive';
  static const String analysis = '/analysis';
  static const String admin = '/admin';
  static const String settings = '/settings';
  static const String scaleAssistant = '/scale-assistant';
  static const String painter = '/painter';
  static const String station = '/station';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            builder: (context) {
              final auth = context.watch<AuthService>();
              return auth.isAuthenticated
                  ? const WebDashboardMain()
                  : const WebLoginScreen();
            },
          );
        }
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      case dashboard:
        return MaterialPageRoute<void>(builder: (_) => const DashboardScreen());
      case onboarding:
        return MaterialPageRoute<void>(builder: (_) => const OnboardingScreen());
      case auth:
        return MaterialPageRoute<void>(builder: (_) => AuthScreen());
      case messages:
        return MaterialPageRoute<void>(builder: (_) => const MessagesScreen());
      case chat:
        final a = settings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return MaterialPageRoute<void>(
          builder: (_) => ChatScreen(groupId: a),
        );
      case autoTableReview:
        final a = settings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return MaterialPageRoute<void>(
          builder: (_) => AutoTableReviewScreen(imagePath: a),
        );
      case camera:
        final id = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => SmartCameraScreen(
            stationId: id is int? ? id : null,
          ),
        );
      case map:
        return MaterialPageRoute<void>(
          builder: (_) {
            final args = settings.arguments;
            return GlobalMapScreen(
              initLocation: args is Map<String, dynamic> ? args : null,
            );
          },
        );
      case archive:
        return MaterialPageRoute<void>(builder: (_) => const ArchiveScreen());
      case analysis:
        return MaterialPageRoute<void>(builder: (_) => const AnalysisScreen());
      case admin:
      case settings:
        return MaterialPageRoute<void>(builder: (_) => const AdminScreen());
      case scaleAssistant:
        return MaterialPageRoute<void>(
          builder: (_) => const ScaleAssistantScreen(),
        );
      case painter:
        final a = settings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return MaterialPageRoute<void>(
          builder: (_) => ImagePainterScreen(imagePath: a),
        );
      case station:
        return MaterialPageRoute<void>(
          builder: (_) {
            final id = settings.arguments;
            return StationSummaryScreen(
              stationId: id is int? ? id : null,
            );
          },
        );
      default:
        return _notFound();
    }
  }

  static Route<dynamic> _notFound() {
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}
