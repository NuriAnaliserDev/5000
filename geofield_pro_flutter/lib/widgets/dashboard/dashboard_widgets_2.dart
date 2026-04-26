import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/station.dart';
import '../../services/settings_controller.dart';
import '../station_tile.dart';

/// Pinned/sliver top bar for the mobile dashboard.
///
/// Shows the app name, welcome message (uses current user name from
/// [SettingsController]), and today's date. Parameters are required so
/// the consumer can pass already-read objects (no provider lookup here —
/// keeps the widget cheap to rebuild).
class DashboardSliverAppBar extends StatelessWidget {
  final SettingsController settings;
  final bool isDark;

  const DashboardSliverAppBar({
    super.key,
    required this.settings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = settings.currentUserName;
    final greeting = name == null || name.isEmpty
        ? 'GeoField Pro'
        : 'Xush kelibsiz, $name';
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return SliverAppBar(
      expandedHeight: 132,
      collapsedHeight: 64,
      toolbarHeight: 64,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12, right: 56),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                greeting,
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.0,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          tooltip: GeoFieldStrings.of(context)?.notifications_screen_title ?? '',
          onPressed: () => Navigator.of(context).pushNamed('/notifications'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class DashboardGpsWarning extends StatelessWidget {
  const DashboardGpsWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'GPS aniqligi past (±12m). Ochiq joyga chiqing.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardRecentHeader extends StatelessWidget {
  final int count;
  const DashboardRecentHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'So\'nggi stansiyalar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/archive'),
            child: Text('Barchasi ($count)'),
          ),
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_clear_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hali stansiyalar yo\'q',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Yangi nuqta qo\'shish uchun + tugmasini bosing',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardStationTile extends StatelessWidget {
  final Station station;
  const DashboardStationTile({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: StationTile(station: station),
    );
  }
}
