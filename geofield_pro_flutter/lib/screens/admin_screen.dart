import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_router.dart';
import '../core/diagnostics/diagnostic_service.dart';
import '../services/auth_service.dart';
import '../services/station_repository.dart';
import '../services/export_service.dart';
import '../services/station_excel_export.dart';
import '../services/settings_controller.dart';
import '../services/theme_controller.dart';
import '../services/location_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_scroll_physics.dart';
import '../utils/app_card.dart';
import '../widgets/common/stitch_screen_background.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final repo = context.read<StationRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.locRead('warning_label')),
        content: Text(
          context.locRead('confirm_delete_all'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.locRead('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.locRead('delete_confirm_btn')),
          ),
        ],
      ),
    );

    if (ok == true) {
      await repo.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.locRead('success_saved'))),
        );
      }
    }
  }

  Future<void> _exportData(
    BuildContext context,
    StationRepository repo, {
    bool isCsv = false,
    bool isExcel = false,
  }) async {
    if (repo.stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('export_no_stations'))),
      );
      return;
    }

    final projects = repo.stations
        .map((s) => s.project)
        .where((p) => p != null)
        .map((e) => e as String)
        .toSet()
        .toList();
    if (!projects.contains(context.loc('all_stations'))) {
      projects.insert(0, context.loc('all_stations'));
    }
    if (!projects.contains(context.loc('today_only'))) {
      projects.insert(1, context.loc('today_only'));
    }

    String? selectedProject = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(context.locRead('export_select_project')),
            backgroundColor: Theme.of(context).colorScheme.surface,
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (c, i) => ListTile(
                  title: Text(projects[i]),
                  onTap: () => Navigator.of(ctx).pop(projects[i]),
                ),
              ),
            ),
          );
        });

    if (selectedProject == null) return;
    if (!context.mounted) return;

    final toExport = selectedProject == context.locRead('all_stations')
        ? repo.stations
        : selectedProject == context.locRead('today_only')
            ? repo.stations.where((s) {
                final now = DateTime.now();
                return s.date.year == now.year &&
                    s.date.month == now.month &&
                    s.date.day == now.day;
              }).toList()
            : repo.stations.where((s) => s.project == selectedProject).toList();

    if (toExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('no_stations_in_project'))),
      );
      return;
    }

    final file = isExcel
        ? await StationExcelExport.writeStationsFile(toExport)
        : isCsv
            ? await ExportService.exportToCsv(toExport)
            : await ExportService.exportToGeoJson(toExport);

    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)],
        text: 'GeoField Pro N: $selectedProject export');
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final count = repo.stations.length;
    final settings = context.watch<SettingsController>();
    final themeCtrl = context.watch<ThemeController>();
    final surf = Theme.of(context).colorScheme.surface;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = ListView(
      physics: AppScrollPhysics.list(),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, AppBottomNavBar.listScrollEndGap(context)),
      children: [
        _profileCard(context, settings, onSurf),
        AppCard(
          opacity: isDark ? 0.12 : 0.45,
          blur: 16,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GPS GEOFENCE & TRACKING',
                style: TextStyle(
                  color: onSurf.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.home_work, color: Colors.orange),
                title: const Text('Baza Lokatsiyasini Qotirish (Home Camp)'),
                subtitle: Text(settings.baseLat != null
                    ? '${settings.baseLat!.toStringAsFixed(5)}, ${settings.baseLng!.toStringAsFixed(5)}'
                    : 'Baza belgilanmagan'),
                trailing: IconButton(
                  icon: Icon(
                      settings.baseLat != null
                          ? Icons.location_off
                          : Icons.add_location_alt,
                      color: Colors.orange),
                  onPressed: () async {
                    if (settings.baseLat != null) {
                      settings.clearBaseLocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Baza o\'chirildi')));
                    } else {
                      final loc =
                          context.read<LocationService>().currentPosition;
                      if (loc != null) {
                        settings.setBaseLocation(loc.latitude, loc.longitude);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Joriy joylashuv Baza sifatida qotirildi')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('GPS topilmadi, kuting...')));
                      }
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_delete, color: Colors.redAccent),
                title: const Text('Arxivni Avtokunduz Tozalash (Auto-Purge)'),
                subtitle: const Text(
                    'Muddatdan o\'tgan marshrutlar arvixdan fonda tozalari'),
                trailing: SizedBox(
                  width: 80,
                  child: DropdownButton<int>(
                    value: settings.autoPurgeDays,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 kun')),
                      DropdownMenuItem(value: 30, child: Text('30 kun')),
                      DropdownMenuItem(value: 90, child: Text('3 oy')),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.autoPurgeDays = v;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.loc('admin'),
          style: TextStyle(
            color: onSurf.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${context.loc('total_stations')}: $count',
          style: TextStyle(color: onSurf),
        ),
        const SizedBox(height: 24),
        // NEW SETTINGS_section (glass)
        AppCard(
          opacity: isDark ? 0.12 : 0.45,
          blur: 16,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc('general_settings_section'),
                style: TextStyle(
                  color: onSurf.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language, color: Color(0xFF1976D2)),
                title: Text(context.loc('language')),
                trailing: DropdownButton<String>(
                  value: settings.language,
                  items: const [
                    DropdownMenuItem(value: 'uz', child: Text('O‘zbekcha')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.language = v;
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.battery_saver, color: Colors.green),
                title: Text(context.loc('eco_mode')),
                value: settings.ecoMode,
                onChanged: (v) => settings.ecoMode = v,
                activeThumbColor: const Color(0xFF1976D2),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary:
                    const Icon(Icons.settings_rounded, color: Colors.redAccent),
                title: Text(context.loc('expert_mode')),
                subtitle: Text(
                  'Professional geologik funksiyalar va kengaytirilgan forma',
                  style: TextStyle(
                      fontSize: 11, color: onSurf.withValues(alpha: 0.55)),
                ),
                value: settings.expertMode,
                onChanged: (v) => settings.expertMode = v,
                activeThumbColor: const Color(0xFF1976D2),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.grid_on, color: Color(0xFF1976D2)),
                title: Text(context.loc('snap_to_grid_label')),
                trailing: DropdownButton<int>(
                  value: settings.snapToGridMeters,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0')),
                    DropdownMenuItem(value: 5, child: Text('5 m')),
                    DropdownMenuItem(value: 10, child: Text('10 m')),
                    DropdownMenuItem(value: 25, child: Text('25 m')),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.snapToGridMeters = v;
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.compass_calibration,
                    color: Color(0xFF1976D2)),
                title: Text(context.loc('magnetic_declination')),
                subtitle: Text(context.loc('magnetic_declination_desc')),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    textAlign: TextAlign.end,
                    decoration:
                        const InputDecoration(suffixText: '°', isDense: true),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null) settings.magneticDeclination = d;
                    },
                    controller: TextEditingController(
                        text: settings.magneticDeclination.toString()),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Hisobdan chiqish',
              style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            await context.read<AuthService>().logout();
            if (!context.mounted) return;
            final s = context.read<SettingsController>();
            s.clearLocalDisplayName();
            s.forgetAuth();
            context.go(AppRouter.auth);
          },
        ),
        const SizedBox(height: 24),
        Text(
          context.loc('actions_label'),
          style: TextStyle(
            color: onSurf.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor:
                Colors.white, // Changed from black for better visibility
          ),
          onPressed: () => _confirmClear(context),
          icon: const Icon(Icons.delete_forever),
          label: Text(context.loc('delete')),
        ),
        const SizedBox(height: 16),
        AppCard(
          opacity: isDark ? 0.12 : 0.45,
          blur: 16,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc('export_actions_section'),
                style: TextStyle(
                  color: onSurf.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _gradientPillButton(
                      onTap: () => _exportData(context, repo, isCsv: true),
                      icon: Icons.table_chart,
                      label: context.loc('export_csv'),
                      colors: const [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gradientPillButton(
                      onTap: () => _exportData(context, repo, isCsv: false),
                      icon: Icons.public,
                      label: context.loc('export_geojson'),
                      colors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gradientPillButton(
                      onTap: () => _exportData(context, repo, isExcel: true),
                      icon: Icons.table_view,
                      label: context.loc('export_stations_excel'),
                      colors: const [Color(0xFF6A1B9A), Color(0xFF4527A0)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.loc('app_look_label'),
          style: TextStyle(
            color: onSurf.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(context.loc('theme_light')),
              icon: const Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(context.loc('theme_dark')),
              icon: const Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(context.loc('theme_system')),
              icon: const Icon(Icons.phone_android),
            ),
          ],
          selected: {themeCtrl.mode},
          onSelectionChanged: (values) {
            final mode = values.first;
            themeCtrl.setMode(mode);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1976D2);
              }
              return onSurf.withValues(alpha: 0.15);
            }),
            foregroundColor: WidgetStateProperty.all(onSurf),
          ),
        ),
        const SizedBox(height: 24),
        Divider(color: onSurf.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          context.loc('about_app'),
          style: TextStyle(
            color: onSurf.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.loc('app_description'),
          style: TextStyle(color: onSurf.withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: onSurf.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: onSurf.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Software: GeoField Pro N (Field Companion)',
                style: TextStyle(
                    color: onSurf.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Muallif: Toshpo‘latov Nodir',
                style: TextStyle(
                    color: onSurf.withValues(alpha: 0.7), fontSize: 11),
              ),
              Text(
                'AI Dasturchi: Codex (OpenAI) + Antigravity',
                style: TextStyle(
                    color: onSurf.withValues(alpha: 0.85), fontSize: 11),
              ),
              Text(
                'AI Support: Antigravity (Google DeepMind) Collaboration',
                style: TextStyle(
                    color: onSurf.withValues(alpha: 1.0),
                    fontSize: 10,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text(
                'Imkoniyatlar: GPS/UTM, geologik kamera (strike/dip/azimut), foto va audio qayd, '
                'offline xarita, trek marshrut, geologik chiziq va poligon chizish, KML/DXF import, '
                'CSV/GeoJSON/KML/GPX/PDF eksport, stereonet va statistik tahlil, real-time chat, '
                'bulut sinxronizatsiya, xavfsizlik (lock/auth), ko‘p tilli interfeys (UZ/EN/TR).',
                style: TextStyle(
                    color: onSurf.withValues(alpha: 0.78),
                    fontSize: 10.5,
                    height: 1.35),
              ),
              const Divider(height: 16),
              Text(
                '${context.loc('version')}: v${settings.appVersion}',
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          opacity: isDark ? 0.12 : 0.45,
          blur: 16,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc('admin_diagnostics_section'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu, color: Colors.blueGrey),
                title: Text(context.loc('admin_diagnostics_view_logs')),
                subtitle: Text(context.loc('admin_diagnostics_view_logs_desc')),
                onTap: () async {
                  final logs = await DiagnosticService.instance.getLogs();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Diagnostics Log'),
                        content: SingleChildScrollView(
                          child: Text(
                            logs,
                            style: const TextStyle(
                                fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(context.loc('admin_diagnostics_close')),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.share, color: Colors.blue),
                title: Text(context.loc('admin_diagnostics_share_logs')),
                onTap: () async {
                  final file = await DiagnosticService.instance.getLogFile();
                  if (file != null && await file.exists()) {
                    await Share.shareXFiles([XFile(file.path)],
                        text: 'GeoField Pro Diagnostics Log');
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(context.loc('admin_diagnostics_not_found'))),
                      );
                    }
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.cleaning_services, color: Colors.orange),
                title: Text(context.loc('admin_diagnostics_clear_logs')),
                onTap: () async {
                  await DiagnosticService.instance.clearLogs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              context.loc('admin_diagnostics_clear_success'))),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : surf,
      extendBody: isDark,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : surf,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(context.loc('admin_full_title')),
      ),
      body: isDark
          ? Stack(
              fit: StackFit.expand,
              children: [
                const StitchScreenBackground(),
                bodyContent,
              ],
            )
          : bodyContent,
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/admin'),
    );
  }

  Widget _profileCard(
      BuildContext context, SettingsController settings, Color onSurf) {
    final name = settings.currentUserName ?? context.loc('dashboard');
    final initial =
        name.isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'G';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        opacity: isDark ? 0.14 : 0.45,
        blur: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc('profile_section_label'),
              style: TextStyle(
                color: onSurf.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      const Color(0xFF1976D2).withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: onSurf,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.expertMode
                            ? context.loc('role_geologist_admin')
                            : 'Geolog',
                        style: TextStyle(
                            fontSize: 12,
                            color: onSurf.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPillButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required List<Color> colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
