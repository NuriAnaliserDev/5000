import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/station.dart';
import '../../services/boundary_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_controller.dart';
import '../../services/station_repository.dart';
import '../../utils/app_card.dart';
import '../../utils/app_localizations.dart';
import '../../utils/auto_scroll_text.dart';

// --- QUICK TOOLS ---
class DashboardQuickTools extends StatelessWidget {
  final LocationService loc;
  final SettingsController settings;
  final bool isDark;

  const DashboardQuickTools({
    super.key,
    required this.loc,
    required this.settings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppCard(
      opacity: isDark ? 0.12 : 0.6,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runAlignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 10,
        children: [
          _buildQuickToolItem(
            context,
            Icons.map_rounded,
            context.loc('map'),
            primary,
            () => Navigator.pushNamed(context, '/map'),
          ),
          _buildQuickToolItem(
            context,
            Icons.photo_camera_rounded,
            context.loc('camera'),
            primary,
            () => Navigator.pushNamed(context, '/camera'),
          ),
          _buildQuickToolItem(
            context,
            Icons.maps_home_work_rounded,
            GeoFieldStrings.of(context)?.field_workshop_title ?? 'Field workshop',
            const Color(0xFF2E7D32),
            () => Navigator.pushNamed(context, AppRouter.fieldWorkshop),
          ),
          _buildQuickToolItem(
            context,
            Icons.alt_route_rounded,
            context.loc('map_track_fab_aria'),
            primary,
            () => Navigator.pushNamed(context, '/map'),
          ),
          _buildQuickToolItem(
            context,
            Icons.mic_rounded,
            context.loc('voice_record'),
            primary,
            () => _openCameraForVoice(context),
          ),
          Tooltip(
            message: GeoFieldStrings.of(context)?.sync_purpose_tooltip ?? '',
            child: _buildQuickToolItem(
              context,
              Icons.cloud_sync_rounded,
              context.loc('sync'),
              primary,
              () => context.read<StationRepository>().syncAllToCloud(),
            ),
          ),
          _buildQuickToolItem(
            context,
            Icons.file_upload_outlined,
            context.loc('dashboard_gis_import'),
            primary,
            () => _importGisFromDashboard(context),
          ),
          _buildQuickToolItem(
            context,
            Icons.file_download_outlined,
            context.loc('dashboard_data_export'),
            primary,
            () => Navigator.pushNamed(context, '/archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _importGisFromDashboard(BuildContext context) async {
    final boundary = context.read<BoundaryService>();
    final s = GeoFieldStrings.of(context);
    if (s == null) return;
    try {
      final r = await boundary.importFileFromWeb();
      if (!context.mounted) return;
      if (r == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.gis_import_done(r.importedCount, r.skippedCount)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openCameraForVoice(BuildContext context) async {
    await Navigator.pushNamed(context, '/camera');
    if (!context.mounted) return;
    final s = GeoFieldStrings.of(context)?.voice_open_camera_hint;
    if (s == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildQuickToolItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 76,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PROJECT PICKER ---
class DashboardProjectPicker extends StatelessWidget {
  final List<Station> allStations;

  const DashboardProjectPicker({super.key, required this.allStations});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.grey.shade200;
    final projects = settings.projects;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, color: Color(0xFF1976D2)),
          const SizedBox(width: 10),
          Text(
            '${context.loc('project')}:',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.currentProject,
                dropdownColor: cardColor,
                isExpanded: true,
                items: projects
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: AutoScrollText(
                          text: p,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  settings.currentProject = v;
                },
              ),
            ),
          ),
          if (settings.currentProject != 'Default') ...[
            IconButton(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
              onPressed: () => _editProject(context, settings),
            ),
            IconButton(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
              onPressed: () => _deleteProject(context, settings),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            tooltip: context.loc('new_project_title'),
            onPressed: () => _createProject(context, settings),
            icon: const Icon(Icons.add, color: Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }

  Future<void> _editProject(BuildContext context, SettingsController settings) async {
    final ctrl = TextEditingController(text: settings.currentProject);
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('edit_project')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: context.loc('new_project_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(context.loc('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text(context.loc('save')),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final old = settings.currentProject;
    final newName = name.trim();
    if (old == newName) return;
    
    if (!context.mounted) return;
    settings.renameProject(old, newName);
    await context.read<StationRepository>().renameProject(old, newName);
  }

  Future<void> _deleteProject(BuildContext context, SettingsController settings) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('delete_project_title')),
        content: Text(context.loc('delete_project_warn')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.loc('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.loc('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      final p = settings.currentProject;
      settings.deleteProject(p);
      await context.read<StationRepository>().deleteProject(p);
    }
  }

  Future<void> _createProject(BuildContext context, SettingsController settings) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.loc('new_project_title')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.loc('new_project_hint'),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(context.loc('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text(context.loc('create_btn')),
          ),
        ],
      ),
    );
    if (name == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    settings.currentProject = trimmed;
  }
}

// End of file
