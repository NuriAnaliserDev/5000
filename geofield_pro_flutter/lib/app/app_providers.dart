import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/di/dependency_injection.dart';

import '../services/auth_service.dart';
import '../services/boundary_service.dart';
import '../services/chat_repository.dart';
import '../services/cloud_sync_service.dart';
import '../services/geological_line_repository.dart';
import '../services/map_structure_repository.dart';
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
/// Dependency Chain (ChangNotifierProxyProvider) to'liq bekor qilindi.
/// Endi servislarni UI ga yetkazish uchun GetIt ishlatiladi.
List<SingleChildWidget> buildAppChangeNotifierProviders() {
  return [
    ChangeNotifierProvider<CloudSyncService>(
      lazy: true,
      create: (_) => sl<CloudSyncService>(),
    ),
    ChangeNotifierProvider<StationRepository>(
      lazy: true,
      create: (_) => sl<StationRepository>(),
    ),
    ChangeNotifierProvider<ThemeController>(
        lazy: false, create: (_) => sl<ThemeController>()),
    ChangeNotifierProvider<AuthService>(
        lazy: false, create: (_) => sl<AuthService>()),
    ChangeNotifierProvider<SettingsController>(
        lazy: false, create: (_) => sl<SettingsController>()),
    ChangeNotifierProvider<ChatRepository>(
      lazy: true,
      create: (_) => sl<ChatRepository>(),
    ),
    ChangeNotifierProvider<TrackService>(
      lazy: true,
      create: (_) => sl<TrackService>(),
    ),
    ChangeNotifierProvider<LocationService>(
        lazy: true, create: (_) => sl<LocationService>()),
    ChangeNotifierProvider<BoundaryService>(
        lazy: true, create: (_) => sl<BoundaryService>()),
    ChangeNotifierProvider<MineReportRepository>(
        lazy: true, create: (_) => sl<MineReportRepository>()),
    ChangeNotifierProvider<GeologicalLineRepository>(
      lazy: true,
      create: (_) => sl<GeologicalLineRepository>(),
    ),
    ChangeNotifierProvider<MapStructureRepository>(
      lazy: true,
      create: (_) => sl<MapStructureRepository>(),
    ),
    ChangeNotifierProvider<SecurityProvider>(
        lazy: true, create: (_) => sl<SecurityProvider>()),
    ChangeNotifierProvider<PresenceService>(
        lazy: true, create: (_) => sl<PresenceService>()),
    ChangeNotifierProvider<SosService>(
        lazy: true, create: (_) => sl<SosService>()),
  ];
}
