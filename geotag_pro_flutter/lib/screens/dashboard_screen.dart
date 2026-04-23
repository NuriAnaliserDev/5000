import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/station_repository.dart';
import '../models/station.dart';
import '../utils/app_nav_bar.dart';
import '../services/settings_controller.dart';
import '../services/location_service.dart';
import '../services/track_service.dart';

// Components
import '../widgets/dashboard/dashboard_components.dart';
import '../widgets/dashboard/dashboard_mini_map_box.dart';
import '../widgets/dashboard/dashboard_session_box.dart';
import '../widgets/dashboard/dashboard_widgets_2.dart';
import '../widgets/dashboard/tiles/utm_tile.dart';
import '../widgets/dashboard/tiles/fisher_reliability_tile.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_sidebar.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_bento_grid.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_project_section.dart';
import '../widgets/dashboard/desktop/dashboard_desktop_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Timer and refresh logic is completely removed from the screen level.
  // It is now encapsulated in `DashboardSessionBox`.
  
  int _selectedIndex = 0;
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add routing logic if needed for desktop sidebar
  }


  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final settings = context.watch<SettingsController>();
    final locService = context.read<LocationService>();
    final trackSvc = context.read<TrackService>();
    final allStations = repo.stations;
    final stations = allStations
        .where((s) => (s.project ?? 'Default') == settings.currentProject)
        .toList();

    final surf = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: surf,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWideLayout(context, settings, locService, trackSvc, stations, allStations, isDark);
          }
          return _buildNarrowLayout(context, settings, locService, trackSvc, stations, allStations, isDark);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => Navigator.of(context).pushNamed('/camera'),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 900 
        ? const AppBottomNavBar(activeRoute: '/dashboard') 
        : null,
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context, 
    SettingsController settings, 
    LocationService locService, 
    TrackService trackSvc, 
    List<Station> stations, 
    List<Station> allStations, 
    bool isDark
  ) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                  DashboardQuickTools(loc: locService, settings: settings, isDark: isDark),
                  const SizedBox(height: 12),
                  Consumer<LocationService>(
                    builder: (context, loc, _) => DashboardMiniMapBox(loc: loc, settings: settings, isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: Consumer<LocationService>(
                      builder: (context, loc, _) => UTMTile(loc: loc, isDark: isDark),
                    ),
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

          if (settings.currentUserRole != 'Sampler')
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: DashboardProjectPicker(allStations: allStations)),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: DashboardRecentHeader(count: stations.length)),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: stations.isEmpty
                ? const SliverToBoxAdapter(child: DashboardEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DashboardStationTile(station: stations[index]),
                      childCount: stations.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context, 
    SettingsController settings, 
    LocationService locService, 
    TrackService trackSvc, 
    List<Station> stations, 
    List<Station> allStations, 
    bool isDark
  ) {
    return Row(
      children: [
        DashboardDesktopSidebar(
          selectedIndex: _selectedIndex,
          onSelected: _onItemTapped,
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardDesktopHeader(settings: settings, isDark: isDark),
                      const SizedBox(height: 24),
                      Consumer<LocationService>(
                        builder: (context, loc, _) => DashboardDesktopBentoGrid(
                          stations: stations,
                          isDark: isDark,
                        ),
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
