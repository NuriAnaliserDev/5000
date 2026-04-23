import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/station_repository.dart';
import '../services/export_service.dart';
import '../services/settings_controller.dart';
import '../services/theme_controller.dart';
import '../services/location_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_scroll_physics.dart';

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

  Future<void> _exportData(BuildContext context, StationRepository repo, bool isCsv) async {
    if (repo.stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('export_no_stations'))),
      );
      return;
    }
    
    final projects = repo.stations.map((s) => s.project).where((p) => p != null).map((e) => e as String).toSet().toList();
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
      }
    );
    
    if (selectedProject == null) return;
    if (!context.mounted) return;
    
    final toExport = selectedProject == context.locRead('all_stations') 
        ? repo.stations 
        : selectedProject == context.locRead('today_only')
            ? repo.stations.where((s) {
                final now = DateTime.now();
                return s.date.year == now.year && s.date.month == now.month && s.date.day == now.day;
              }).toList()
            : repo.stations.where((s) => s.project == selectedProject).toList();
        
    if (toExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.locRead('no_stations_in_project'))),
      );
      return;
    }

    final file = isCsv 
        ? await ExportService.exportToCsv(toExport)
        : await ExportService.exportToGeoJson(toExport);
        
    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'GeoField Pro N: $selectedProject export');
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final count = repo.stations.length;
    final settings = context.watch<SettingsController>();
    final themeCtrl = context.watch<ThemeController>();
    final surf = Theme.of(context).colorScheme.surface;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        backgroundColor: surf,
        title: Text(context.loc('admin')),
      ),
      body: ListView(
        physics: AppScrollPhysics.list(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
            subtitle: Text(settings.baseLat != null ? '${settings.baseLat!.toStringAsFixed(5)}, ${settings.baseLng!.toStringAsFixed(5)}' : 'Baza belgilanmagan'),
            trailing: IconButton(
              icon: Icon(settings.baseLat != null ? Icons.location_off : Icons.add_location_alt, color: Colors.orange),
              onPressed: () async {
                if (settings.baseLat != null) {
                   settings.clearBaseLocation();
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baza o\'chirildi')));
                } else {
                   final loc = context.read<LocationService>().currentPosition;
                   if (loc != null) {
                     settings.setBaseLocation(loc.latitude, loc.longitude);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joriy joylashuv Baza sifatida qotirildi')));
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS topilmadi, kuting...')));
                   }
                }
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_delete, color: Colors.redAccent),
            title: const Text('Arxivni Avtokunduz Tozalash (Auto-Purge)'),
            subtitle: const Text('Muddatdan o\'tgan marshrutlar arvixdan fonda tozalari'),
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
          // NEW SETTINGS SECTION
          Text(
            context.loc('settings'),
            style: TextStyle(
              color: onSurf.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
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
            secondary: const Icon(Icons.battery_saver, color: Color(0xFF1976D2)),
            title: Text(context.loc('eco_mode')),
            value: settings.ecoMode,
            onChanged: (v) => settings.ecoMode = v,
            activeThumbColor: const Color(0xFF1976D2),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.psychology, color: Color(0xFF1976D2)),
            title: Text(context.loc('expert_mode')),
            subtitle: Text(
              'Professional geologik funksiyalar va kengaytirilgan forma',
              style: TextStyle(fontSize: 11, color: onSurf.withValues(alpha: 0.55)),
            ),
            value: settings.expertMode,
            onChanged: (v) => settings.expertMode = v,
            activeThumbColor: const Color(0xFF1976D2),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Hisobdan chiqish', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await context.read<AuthService>().logout();
              if (!context.mounted) return;
              context.read<SettingsController>().clearLocalDisplayName();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.auth,
                (r) => false,
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.compass_calibration, color: Color(0xFF1976D2)),
            title: Text(context.loc('magnetic_declination')),
            subtitle: Text(context.loc('magnetic_declination_desc')),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                textAlign: TextAlign.end,
                decoration: const InputDecoration(suffixText: '°', isDense: true),
                onChanged: (v) {
                  final d = double.tryParse(v);
                  if (d != null) settings.magneticDeclination = d;
                },
                controller: TextEditingController(text: settings.magneticDeclination.toString()),
              ),
            ),
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
              foregroundColor: Colors.white, // Changed from black for better visibility
            ),
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_forever),
            label: Text(context.loc('delete')),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _exportData(context, repo, true),
            icon: const Icon(Icons.table_chart),
            label: Text(context.loc('export_csv')),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _exportData(context, repo, false),
            icon: const Icon(Icons.public),
            label: Text(context.loc('export_geojson')),
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
                  style: TextStyle(color: onSurf.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Muallif: Toshpo‘latov Nodir',
                  style: TextStyle(color: onSurf.withValues(alpha: 0.7), fontSize: 11),
                ),
                Text(
                  'AI Dasturchi: Codex (OpenAI) + Antigravity',
                  style: TextStyle(color: onSurf.withValues(alpha: 0.85), fontSize: 11),
                ),
                Text(
                  'AI Support: Antigravity (Google DeepMind) Collaboration',
                  style: TextStyle(color: onSurf.withValues(alpha: 1.0), fontSize: 10, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text(
                  'Imkoniyatlar: GPS/UTM, geologik kamera (strike/dip/azimut), foto va audio qayd, '
                  'offline xarita, trek marshrut, geologik chiziq va poligon chizish, KML/DXF import, '
                  'CSV/GeoJSON/KML/GPX/PDF eksport, stereonet va statistik tahlil, real-time chat, '
                  'bulut sinxronizatsiya, xavfsizlik (lock/auth), ko‘p tilli interfeys (UZ/EN/TR).',
                  style: TextStyle(color: onSurf.withValues(alpha: 0.78), fontSize: 10.5, height: 1.35),
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
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/admin'),
    );
  }
}
