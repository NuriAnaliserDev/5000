part of '../dashboard_screen.dart';

mixin DashboardScreenLayoutsMixin on DashboardScreenFields {
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
                Selector<LocationService,
                    ({double lat, double lng, double acc, bool hasFix})>(
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
                      DashboardDesktopHeader(
                          settings: settings, isDark: isDark),
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
