import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/station.dart';
import '../services/location_service.dart';
import '../services/settings_controller.dart';
import '../services/station_repository.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_scroll_physics.dart';

// Components
import '../widgets/dashboard/dashboard_components.dart';
import '../widgets/dashboard/dashboard_mini_map_box.dart';
import '../widgets/dashboard/dashboard_session_box.dart';
import '../widgets/dashboard/dashboard_widgets_2.dart';
import '../widgets/dashboard/tiles/utm_tile.dart';
import '../widgets/dashboard/tiles/fisher_reliability_tile.dart';
import '../widgets/common/stitch_screen_background.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_sidebar.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_bento_grid.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_project_section.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_header.dart';

int _dashboardSettingsToken(SettingsController s) => Object.hash(
      s.currentProject,
      s.mapStyle,
      s.currentUserName,
      Object.hashAll(s.projects),
    );

({double lat, double lng, double acc, bool hasFix}) _locSlice(LocationService loc) {
  final p = loc.currentPosition;
  if (p == null) {
    return (
      lat: loc.latitude,
      lng: loc.longitude,
      acc: loc.accuracy,
      hasFix: false,
    );
  }
  return (
    lat: p.latitude,
    lng: p.longitude,
    acc: p.accuracy,
    hasFix: true,
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select<StationRepository, int>((r) => r.dataGeneration);
    context.select<SettingsController, int>(_dashboardSettingsToken);

    final repo = context.read<StationRepository>();
    final settings = context.read<SettingsController>();
    final locService = context.read<LocationService>();

    final allStations = repo.stations;
    final stations = allStations
        .where((s) => (s.project ?? 'Default') == settings.currentProject)
        .toList();

    final surf = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : surf,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: isDark ? null : BoxDecoration(color: surf),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildWideLayout(context, settings, stations, isDark);
              }
              return _buildNarrowLayout(
                context,
                settings,
                locService,
                stations,
                allStations,
                isDark,
              );
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width <= 900
            ? const AppBottomNavBar(activeRoute: '/dashboard')
            : null,
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    SettingsController settings,
    LocationService locService,
    List<Station> stations,
    List<Station> allStations,
    bool isDark,
  ) {
    final scroll = CustomScrollView(
        physics: AppScrollPhysics.list(),
        slivers: [
          DashboardSliverAppBar(settings: settings, isDark: isDark),
          Selector<LocationService, GpsStatus>(
            selector: (_, loc) => loc.status,
            builder: (context, status, _) {
              if (status == GpsStatus.off) {
                return const SliverToBoxAdapter(child: DashboardGpsWarning());
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!isDark) ...[
                    DashboardQuickTools(
                      loc: locService,
                      settings: settings,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Selector<LocationService, ({double lat, double lng, double acc, bool hasFix})>(
                    selector: (_, loc) => _locSlice(loc),
                    builder: (context, slice, _) {
                      return Column(
                        children: [
                          if (!isDark) ...[
                            DashboardMiniMapBox(
                              userLatLng: slice.hasFix
                                  ? LatLng(slice.lat, slice.lng)
                                  : null,
                              mapStyle: settings.mapStyle,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            height: 160,
                            child: UTMTile(
                              latitude: slice.lat,
                              longitude: slice.lng,
                              accuracyMeters: slice.acc,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: DashboardSessionBox(isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: FisherReliabilityTile(isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: DashboardProjectPicker(allStations: allStations),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: DashboardRecentHeader(count: stations.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: stations.isEmpty
                ? const SliverToBoxAdapter(child: DashboardEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DashboardStationTile(station: stations[index]),
                      childCount: stations.length,
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: AppBottomNavBar.listScrollEndGap(context)),
          ),
        ],
      );

    if (isDark) {
      return SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const StitchScreenBackground(),
            scroll,
          ],
        ),
      );
    }
    return SafeArea(child: scroll);
  }

  Widget _buildWideLayout(
    BuildContext context,
    SettingsController settings,
    List<Station> stations,
    bool isDark,
  ) {
    return Row(
      children: [
        DashboardDesktopSidebar(
          selectedIndex: _selectedIndex,
          onSelected: _onItemTapped,
        ),
        Expanded(
          child: CustomScrollView(
            physics: AppScrollPhysics.list(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardDesktopHeader(settings: settings, isDark: isDark),
                      const SizedBox(height: 24),
                      DashboardDesktopBentoGrid(
                        stations: stations,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),
                      const DashboardDesktopProjectSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
