import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
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
import '../screens/sync/conflict_resolution_screen.dart';
import '../screens/sync/sync_debug_screen.dart';

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
  static const String conflicts = '/conflicts';
  static const String syncDebug = '/sync-debug';

  // --- Type-Safe Navigation Helpers ---

  static void pushChat(BuildContext context, String groupId) {
    context.push(
        Uri(path: chat, queryParameters: {'groupId': groupId}).toString());
  }

  static void pushAutoTableReview(BuildContext context, String path) {
    context.push(
        Uri(path: autoTableReview, queryParameters: {'path': path}).toString());
  }

  static void pushCamera(BuildContext context, {int? stationId}) {
    context.push(Uri(
            path: camera,
            queryParameters:
                stationId != null ? {'stationId': stationId.toString()} : null)
        .toString());
  }

  static void pushMap(BuildContext context,
      {Map<String, dynamic>? initLocation}) {
    Map<String, String> q = {};
    if (initLocation != null) {
      if (initLocation['lat'] != null) {
        q['lat'] = initLocation['lat'].toString();
      }
      if (initLocation['lng'] != null) {
        q['lng'] = initLocation['lng'].toString();
      }
      if (initLocation['zoom'] != null) {
        q['zoom'] = initLocation['zoom'].toString();
      }
    }
    context.push(
        Uri(path: map, queryParameters: q.isNotEmpty ? q : null).toString());
  }

  static void pushFieldWorkshop(BuildContext context,
      {Map<String, dynamic>? initLocation}) {
    Map<String, String> q = {};
    if (initLocation != null) {
      if (initLocation['lat'] != null) {
        q['lat'] = initLocation['lat'].toString();
      }
      if (initLocation['lng'] != null) {
        q['lng'] = initLocation['lng'].toString();
      }
      if (initLocation['zoom'] != null) {
        q['zoom'] = initLocation['zoom'].toString();
      }
    }
    context.push(
        Uri(path: fieldWorkshop, queryParameters: q.isNotEmpty ? q : null)
            .toString());
  }

  static void pushPainter(BuildContext context, String path) {
    context
        .push(Uri(path: painter, queryParameters: {'path': path}).toString());
  }

  static void pushStation(BuildContext context, {int? stationId}) {
    context.push(Uri(
            path: station,
            queryParameters:
                stationId != null ? {'id': stationId.toString()} : null)
        .toString());
  }

  static void goStation(BuildContext context, {int? stationId}) {
    context.go(Uri(
            path: station,
            queryParameters:
                stationId != null ? {'id': stationId.toString()} : null)
        .toString());
  }

  // ------------------------------------

  static final router = GoRouter(
    navigatorKey: globalNavigatorKey,
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) {
          if (kIsWeb) {
            final auth = context.watch<AuthService>();
            return auth.isAuthenticated
                ? const WebDashboardMain()
                : const WebLoginScreen();
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
          final id = state.uri.queryParameters['groupId'];
          if (id == null || id.isEmpty) return const _NotFoundScreen();
          return ChatScreen(groupId: id);
        },
      ),
      GoRoute(
        path: autoTableReview,
        builder: (context, state) {
          final path = state.uri.queryParameters['path'];
          if (path == null || path.isEmpty) return const _NotFoundScreen();
          return AutoTableReviewScreen(imagePath: path);
        },
      ),
      GoRoute(
        path: camera,
        builder: (context, state) {
          final sid = state.uri.queryParameters['stationId'];
          return SmartCameraScreen(
              stationId: sid != null ? int.tryParse(sid) : null);
        },
      ),
      GoRoute(
        path: map,
        builder: (context, state) {
          final lat = state.uri.queryParameters['lat'];
          final lng = state.uri.queryParameters['lng'];
          final zoom = state.uri.queryParameters['zoom'];
          Map<String, dynamic>? initLoc;
          if (lat != null && lng != null) {
            initLoc = {
              'lat': double.tryParse(lat),
              'lng': double.tryParse(lng)
            };
            if (zoom != null) initLoc['zoom'] = double.tryParse(zoom);
          }
          return GlobalMapScreen(initLocation: initLoc);
        },
      ),
      GoRoute(
        path: fieldWorkshop,
        builder: (context, state) {
          final lat = state.uri.queryParameters['lat'];
          final lng = state.uri.queryParameters['lng'];
          final zoom = state.uri.queryParameters['zoom'];
          Map<String, dynamic>? initLoc;
          if (lat != null && lng != null) {
            initLoc = {
              'lat': double.tryParse(lat),
              'lng': double.tryParse(lng)
            };
            if (zoom != null) initLoc['zoom'] = double.tryParse(zoom);
          }
          return GlobalMapScreen(
              initLocation: initLoc, fieldWorkshopMode: true);
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
          final path = state.uri.queryParameters['path'];
          if (path == null || path.isEmpty) return const _NotFoundScreen();
          return ImagePainterScreen(imagePath: path);
        },
      ),
      GoRoute(
        path: station,
        builder: (context, state) {
          final sid = state.uri.queryParameters['id'];
          return StationSummaryScreen(
              stationId: sid != null ? int.tryParse(sid) : null);
        },
      ),
      GoRoute(
        path: conflicts,
        builder: (context, state) => const ConflictResolutionScreen(),
      ),
      GoRoute(
        path: syncDebug,
        builder: (context, state) => const SyncDebugScreen(),
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
