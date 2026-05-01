import 'package:flutter/material.dart';

import '../screens/archive_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/global_map_screen.dart';
import '../screens/smart_camera/smart_camera_screen.dart';
import '../utils/app_nav_bar.dart';
import 'app_router.dart';

/// Mobil ildiz: 4 ta asosiy tab bitta [IndexedStack] + har biri uchun alohida [Navigator].
class MainTabShell extends StatefulWidget {
  const MainTabShell({
    super.key,
    this.initialTabIndex = 0,
    this.initialCameraStationId,
    this.initialMapLocation,
  });

  final int initialTabIndex;
  final int? initialCameraStationId;
  final Map<String, dynamic>? initialMapLocation;

  @override
  State<MainTabShell> createState() => MainTabShellState();
}

class MainTabShellState extends State<MainTabShell> {
  late int _index;
  int? _cameraStationId;
  Map<String, dynamic>? _mapLocation;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();
    _index = widget.initialTabIndex.clamp(0, 3);
    _cameraStationId = widget.initialCameraStationId;
    _mapLocation = widget.initialMapLocation;
  }

  /// `cameraStationId` — faqat `index == 2` bo‘lganda qo‘llanadi; boshqa tabda `null` bo‘ladi.
  void selectTab(
    int index, {
    Map<String, dynamic>? mapLocation,
    int? cameraStationId,
  }) {
    setState(() {
      _index = index.clamp(0, 3);
      if (mapLocation != null) {
        _mapLocation = mapLocation;
      }
      if (_index == 2) {
        _cameraStationId = cameraStationId;
      } else {
        _cameraStationId = null;
      }
    });
  }

  int get currentTabIndex => _index;

  String _routeForIndex(int i) {
    switch (i) {
      case 0:
        return AppRouter.dashboard;
      case 1:
        return AppRouter.map;
      case 2:
        return AppRouter.camera;
      default:
        return AppRouter.archive;
    }
  }

  void _onShellTabTap(String route) {
    final idx = switch (route) {
      AppRouter.dashboard => 0,
      AppRouter.map => 1,
      AppRouter.camera => 2,
      AppRouter.archive => 3,
      _ => _index,
    };
    if (idx == 2) {
      selectTab(2, cameraStationId: null);
    } else {
      selectTab(idx);
    }
  }

  Widget _tabNavigator(int tabIndex, Widget child) {
    return Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateInitialRoutes: (NavigatorState nav, String initialRoute) {
        return [
          MaterialPageRoute<void>(builder: (_) => child),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainTabScope(
      shellState: this,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _tabNavigator(0, const DashboardScreen(embedded: true)),
            _tabNavigator(
              1,
              GlobalMapScreen(
                embedded: true,
                initLocation: _mapLocation,
              ),
            ),
            _tabNavigator(
              2,
              SmartCameraScreen(
                key: ValueKey<int?>(_cameraStationId),
                embedded: true,
                tabVisible: _index == 2,
                stationId: _cameraStationId,
              ),
            ),
            _tabNavigator(3, const ArchiveScreen(embedded: true)),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          activeRoute: _routeForIndex(_index),
          useShellNavigation: true,
          onShellTabSelected: _onShellTabTap,
        ),
      ),
    );
  }
}

class MainTabScope extends InheritedWidget {
  const MainTabScope({
    super.key,
    required this.shellState,
    required super.child,
  });

  final MainTabShellState shellState;

  /// [dependOnInheritedWidgetOfExactType] ishlatilmaydi — marshrutlar `getElementForInheritedWidgetOfExactType` orqali.
  static MainTabShellState? maybeOf(BuildContext context) {
    final el = context.getElementForInheritedWidgetOfExactType<MainTabScope>();
    final w = el?.widget;
    return w is MainTabScope ? w.shellState : null;
  }

  @override
  bool updateShouldNotify(MainTabScope oldWidget) =>
      oldWidget.shellState.currentTabIndex != shellState.currentTabIndex;
}
