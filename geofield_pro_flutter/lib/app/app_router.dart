import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_transitions.dart';
import 'platform_gate.dart';
import '../screens/archive_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/auto_table_review_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/global_map_screen.dart';
import '../screens/image_painter_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/notifications_feed_screen.dart';
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
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String autoTableReview = '/auto-table-review';
  static const String camera = '/camera';
  static const String map = '/map';
  /// Pro maydon: bitta oynada qatlam, KML/DXF, chizim, struktura.
  static const String fieldWorkshop = '/field-workshop';
  static const String archive = '/archive';
  static const String analysis = '/analysis';
  static const String admin = '/admin';
  static const String settings = '/settings';
  static const String scaleAssistant = '/scale-assistant';
  static const String painter = '/painter';
  static const String station = '/station';

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        if (kIsWeb) {
          return AppPageRoutes.material<void>((context) {
            final auth = context.watch<AuthService>();
            return auth.isAuthenticated
                ? const WebDashboardMain()
                : const WebLoginScreen();
          });
        }
        return AppPageRoutes.material<void>((_) => const SplashScreen());
      case dashboard:
        return AppPageRoutes.material<void>((_) => const PlatformGate());
      case onboarding:
        return AppPageRoutes.material<void>((_) => const OnboardingScreen());
      case auth:
        return AppPageRoutes.material<void>((_) => AuthScreen());
      case messages:
        return AppPageRoutes.material<void>((_) => const MessagesScreen());
      case notifications:
        return AppPageRoutes.material<void>((_) => const NotificationsFeedScreen());
      case chat:
        final a = routeSettings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return AppPageRoutes.material<void>(
          (_) => ChatScreen(groupId: a),
        );
      case autoTableReview:
        final a = routeSettings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return AppPageRoutes.material<void>(
          (_) => AutoTableReviewScreen(imagePath: a),
        );
      case camera:
        final id = routeSettings.arguments;
        int? sid;
        if (id is int) {
          sid = id;
        } else if (id is num) {
          sid = id.toInt();
        }
        return AppPageRoutes.material<void>(
          (_) => SmartCameraScreen(stationId: sid),
        );
      case map:
        return AppPageRoutes.material<void>((_) {
          final args = routeSettings.arguments;
          return GlobalMapScreen(
            initLocation: args is Map<String, dynamic> ? args : null,
          );
        });
      case fieldWorkshop:
        return AppPageRoutes.material<void>((_) {
          final args = routeSettings.arguments;
          return GlobalMapScreen(
            initLocation: args is Map<String, dynamic> ? args : null,
            fieldWorkshopMode: true,
          );
        });
      case archive:
        return AppPageRoutes.material<void>((_) => const ArchiveScreen());
      case analysis:
        return AppPageRoutes.material<void>((_) => const AnalysisScreen());
      case AppRouter.admin:
      case AppRouter.settings:
        return AppPageRoutes.material<void>((_) => const AdminScreen());
      case scaleAssistant:
        return AppPageRoutes.material<void>(
          (_) => const ScaleAssistantScreen(),
        );
      case painter:
        final a = routeSettings.arguments;
        if (a is! String || a.isEmpty) {
          return _notFound();
        }
        return AppPageRoutes.material<void>(
          (_) => ImagePainterScreen(imagePath: a),
        );
      case station:
        return AppPageRoutes.material<void>((_) {
          final id = routeSettings.arguments;
          int? sid;
          if (id is int) {
            sid = id;
          } else if (id is num) {
            sid = id.toInt();
          }
          return StationSummaryScreen(stationId: sid);
        });
      default:
        return _notFound();
    }
  }

  static Route<dynamic> _notFound() {
    return AppPageRoutes.material<void>(
      (_) => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}
