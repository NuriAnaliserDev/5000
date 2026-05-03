import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../l10n/app_strings.dart';
import '../screens/web/web_dashboard_main.dart';
import '../screens/web/web_login_screen.dart';

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
  static const String fieldWorkshop = '/field-workshop';
  static const String archive = '/archive';
  static const String analysis = '/analysis';
  static const String admin = '/admin';
  static const String settings = '/settings';
  static const String scaleAssistant = '/scale-assistant';
  static const String painter = '/painter';
  static const String station = '/station';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) {
          if (kIsWeb) {
            final auth = context.watch<AuthService>();
            return auth.isAuthenticated ? const WebDashboardMain() : const WebLoginScreen();
          }
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const PlatformGate(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: auth,
        builder: (context, state) => AuthScreen(),
      ),
      GoRoute(
        path: messages,
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsFeedScreen(),
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final id = state.extra as String?;
          if (id == null || id.isEmpty) return const _NotFoundScreen();
          return ChatScreen(groupId: id);
        },
      ),
      GoRoute(
        path: autoTableReview,
        builder: (context, state) {
          final path = state.extra as String?;
          if (path == null || path.isEmpty) return const _NotFoundScreen();
          return AutoTableReviewScreen(imagePath: path);
        },
      ),
      GoRoute(
        path: camera,
        builder: (context, state) {
          final sid = state.extra as int?;
          return SmartCameraScreen(stationId: sid);
        },
      ),
      GoRoute(
        path: map,
        builder: (context, state) {
          final initLoc = state.extra as Map<String, dynamic>?;
          return GlobalMapScreen(initLocation: initLoc);
        },
      ),
      GoRoute(
        path: fieldWorkshop,
        builder: (context, state) {
          final initLoc = state.extra as Map<String, dynamic>?;
          return GlobalMapScreen(initLocation: initLoc, fieldWorkshopMode: true);
        },
      ),
      GoRoute(
        path: archive,
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(
        path: analysis,
        builder: (context, state) => const AnalysisScreen(),
      ),
      GoRoute(
        path: admin,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: scaleAssistant,
        builder: (context, state) => const ScaleAssistantScreen(),
      ),
      GoRoute(
        path: painter,
        builder: (context, state) {
          final path = state.extra as String?;
          if (path == null || path.isEmpty) return const _NotFoundScreen();
          return ImagePainterScreen(imagePath: path);
        },
      ),
      GoRoute(
        path: station,
        builder: (context, state) {
          var sid = state.extra;
          if (sid is num) {
            return StationSummaryScreen(stationId: sid.toInt());
          }
          return const StationSummaryScreen();
        },
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final loc = GeoFieldStrings.of(context);
    final title = loc?.route_not_found_title ?? 'Page not found';
    final body = loc?.route_not_found_body ?? '';
    final back = loc?.route_not_found_back ?? 'Back';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    context.go(AppRouter.dashboard);
                  },
                  child: Text(back),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
