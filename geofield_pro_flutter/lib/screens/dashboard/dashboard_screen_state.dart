part of '../dashboard_screen.dart';

class _DashboardScreenState extends State<DashboardScreen>
    with DashboardScreenFields, DashboardScreenLayoutsMixin {
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
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
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
        bottomNavigationBar:
            !widget.embedded && MediaQuery.of(context).size.width <= 900
                ? const AppBottomNavBar(activeRoute: '/dashboard')
                : null,
      ),
    );
  }
}
