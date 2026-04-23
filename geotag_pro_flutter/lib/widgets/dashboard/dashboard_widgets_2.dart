import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../station_tile.dart';
import '../../models/station.dart';

class DashboardSliverAppBar extends StatelessWidget {
  const DashboardSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GeoField Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
            Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey)),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
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
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(child: Text('GPS aniqligi past (±12m). Ochiq joyga chiqing.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
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
          const Text('Recent Stations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(onPressed: () {}, child: Text('See All ($count)')),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_clear_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Hali stansiyalar yo\'q', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Yangi nuqta qo\'shish uchun + tugmasini bosing', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
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
