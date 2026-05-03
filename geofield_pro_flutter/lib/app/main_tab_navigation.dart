import 'package:flutter/material.dart';

import 'app_router.dart';
import 'main_tab_shell.dart';

/// Asosiy tablar: shell ichida bo‘lsa indeks, aks holda klassik [Navigator.pushNamed].
class MainTabNavigation {
  MainTabNavigation._();

  static const int dashboard = 0;
  static const int map = 1;
  static const int camera = 2;
  static const int archive = 3;

  static void selectTab(
    BuildContext context,
    int index, {
    Map<String, dynamic>? mapLocation,
    int? cameraStationId,
  }) {
    final shell = MainTabScope.maybeOf(context);
    if (shell != null) {
      shell.selectTab(
        index,
        mapLocation: mapLocation,
        cameraStationId: cameraStationId,
      );
      return;
    }
    switch (index.clamp(0, 3)) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
        break;
      case 1:
        Navigator.of(context).pushNamed(AppRouter.map, arguments: mapLocation);
        break;
      case 2:
        Navigator.of(context)
            .pushNamed(AppRouter.camera, arguments: cameraStationId);
        break;
      default:
        Navigator.of(context).pushNamed(AppRouter.archive);
    }
  }

  static void openDashboard(BuildContext context) =>
      selectTab(context, dashboard);

  static void openMap(BuildContext context, {Map<String, dynamic>? args}) =>
      selectTab(context, map, mapLocation: args);

  static void openCamera(BuildContext context, {int? stationId}) =>
      selectTab(context, camera, cameraStationId: stationId);

  static void openArchive(BuildContext context) => selectTab(context, archive);
}
