import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/auth_service.dart';
import '../services/boundary_service.dart';
import '../services/chat_repository.dart';
import '../services/cloud_sync_service.dart';
import '../services/geological_line_repository.dart';
import '../services/location_service.dart';
import '../services/mine_report_repository.dart';
import '../services/presence_service.dart';
import '../services/security_provider.dart';
import '../services/settings_controller.dart';
import '../services/sos_service.dart';
import '../services/station_repository.dart';
import '../services/theme_controller.dart';
import '../services/track_service.dart';

/// [main.dart] dagi [MultiProvider]. [CloudSyncService] va boshqa og‘ir
/// servislar [lazy: true] — faqat kerak bo‘lganda yuklanadi.
List<SingleChildWidget> buildAppChangeNotifierProviders() {
  return [
    ChangeNotifierProvider<CloudSyncService>(
      lazy: true,
      create: (ctx) {
        final service = CloudSyncService();
        service.init();
        return service;
      },
    ),
    ChangeNotifierProxyProvider<CloudSyncService, StationRepository>(
      lazy: true,
      create: (ctx) => StationRepository(Provider.of<CloudSyncService>(ctx, listen: false)),
      update: (_, sync, prev) => prev ?? StationRepository(sync),
    ),
    ChangeNotifierProvider<ThemeController>(lazy: false, create: (_) => ThemeController()),
    ChangeNotifierProvider<AuthService>(lazy: false, create: (_) => AuthService()),
    ChangeNotifierProvider<SettingsController>(lazy: false, create: (_) => SettingsController()),
    ChangeNotifierProxyProvider<SettingsController, ChatRepository>(
      lazy: true,
      create: (ctx) => ChatRepository(
        settingsController: Provider.of<SettingsController>(ctx, listen: false),
      ),
      update: (_, settings, chatRepo) => chatRepo ?? ChatRepository(settingsController: settings),
    ),
    ChangeNotifierProxyProvider<CloudSyncService, TrackService>(
      lazy: true,
      create: (ctx) => TrackService(Provider.of<CloudSyncService>(ctx, listen: false)),
      update: (_, sync, prev) => prev ?? TrackService(sync),
    ),
    ChangeNotifierProvider<LocationService>(lazy: true, create: (_) => LocationService()),
    ChangeNotifierProvider<BoundaryService>(lazy: true, create: (_) => BoundaryService()),
    ChangeNotifierProvider<MineReportRepository>(lazy: true, create: (_) => MineReportRepository()),
    ChangeNotifierProvider<GeologicalLineRepository>(
      lazy: true,
      create: (_) {
        final repo = GeologicalLineRepository();
        repo.init();
        return repo;
      },
    ),
    ChangeNotifierProvider<SecurityProvider>(lazy: true, create: (_) => SecurityProvider()),
    ChangeNotifierProvider<PresenceService>(lazy: true, create: (_) => PresenceService()),
    ChangeNotifierProvider<SosService>(lazy: true, create: (_) => SosService()),
  ];
}
