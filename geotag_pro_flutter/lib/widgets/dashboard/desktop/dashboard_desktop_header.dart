import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/settings_controller.dart';
import '../../../services/cloud_sync_service.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_localizations.dart';

class DashboardDesktopHeader extends StatelessWidget {
  final SettingsController settings;
  final bool isDark;

  const DashboardDesktopHeader({super.key, required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.loc('welcome_text'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: isDark ? Colors.white70 : Colors.black54),
                ),
                Text(
                  settings.currentUserName ?? "Geologist",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildWorkstationStatus(context, isDark),
        const SizedBox(width: 24),
        _buildDesktopActionButtons(context),
      ],
    );
  }

  Widget _buildWorkstationStatus(BuildContext context, bool isDark) {
    final syncService = context.watch<CloudSyncService>();
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.wifi,
          label: 'CLOUD',
          color: syncService.isSyncing ? Colors.orange : Colors.green,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: Icons.storage,
          label: syncService.isSyncing ? 'SYNCING' : 'READY',
          color: syncService.isSyncing ? Colors.blue : Colors.green,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 24,
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.read<SettingsController>().currentUserName ?? 'GEOLOGIST',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              context.read<SettingsController>().currentUserRole?.toUpperCase() ?? 'ADMIN',
              style: TextStyle(fontSize: 9, color: Colors.grey.withValues(alpha: 0.8), letterSpacing: 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/camera'),
          icon: const Icon(Icons.add, size: 20),
          label: Text(context.loc('new_station_btn')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.cloud_sync_rounded),
          onPressed: () => context.read<StationRepository>().syncAllToCloud(),
        ),
      ],
    );
  }
}
