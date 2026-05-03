import 'package:get_it/get_it.dart';

import '../../services/auth_service.dart';
import '../../services/boundary_service.dart';
import '../security/access_control_service.dart';
import '../../services/chat_repository.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/geological_line_repository.dart';
import '../../services/location_service.dart';
import '../../services/map_structure_repository.dart';
import '../../services/mine_report_repository.dart';
import '../../services/presence_service.dart';
import '../../services/security_provider.dart';
import '../../services/settings_controller.dart';
import '../../services/sos_service.dart';
import '../../services/station_repository.dart';
import '../../services/theme_controller.dart';
import '../../services/track_service.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // 1. Data Layer (Core configs, Network, Local DB bindings)
  sl.registerLazySingleton<ThemeController>(() => ThemeController());
  sl.registerLazySingleton<SettingsController>(() => SettingsController());
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AccessControlService>(() => AccessControlService());

  sl.registerLazySingleton<CloudSyncService>(() {
    final service = CloudSyncService();
    service.init();
    return service;
  });

  sl.registerLazySingleton<LocationService>(() => LocationService());

  // 2. Domain / Repository Layer
  // Dependensiyalarni zanjirini sindirish (Dependency inversion).
  // Obyektlar to'g'ridan to'g'ri GetIt orqali o'ziga kerakli servislarni oladi.
  sl.registerLazySingleton<StationRepository>(
      () => StationRepository(sl<CloudSyncService>()));
  sl.registerLazySingleton<TrackService>(
      () => TrackService(sl<CloudSyncService>()));

  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepository(settingsController: sl<SettingsController>()));
  sl.registerLazySingleton<MineReportRepository>(() => MineReportRepository());
  sl.registerLazySingleton<BoundaryService>(() => BoundaryService());

  sl.registerLazySingleton<GeologicalLineRepository>(() {
    final r = GeologicalLineRepository();
    r.init();
    return r;
  });

  sl.registerLazySingleton<MapStructureRepository>(() {
    final r = MapStructureRepository();
    r.init();
    return r;
  });

  // 3. Presentation / Features Layer
  sl.registerLazySingleton<SecurityProvider>(() => SecurityProvider());
  sl.registerLazySingleton<PresenceService>(() => PresenceService());
  sl.registerLazySingleton<SosService>(() => SosService());
}
