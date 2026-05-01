import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/app_localizations.dart';
import '../../models/station.dart';
import '../../services/settings_controller.dart';
import '../../utils/app_card.dart';
import '../station_tile.dart';

/// Mobil dashboard uchun yuqori «glass» blok: Stitch mockup’dagi sarlavha kartasi.
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
    final scheme = Theme.of(context).colorScheme;
    final heroTitle = context.loc('dashboard_hero_title');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: AppCard(
          opacity: isDark ? 0.14 : 0.65,
          blur: 20,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heroTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                          height: 1.15,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        greeting,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.2,
                          height: 1.15,
                          color: scheme.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: scheme.onSurface),
                  tooltip: context.loc('notifications_screen_title'),
                  onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'So\'nggi stansiyalar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/archive'),
            child: Text(
              context.loc('dashboard_view_all'),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        opacity: isDark ? 0.12 : 0.55,
        blur: 18,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EmptyStateMapPainter(color: scheme.onSurface.withValues(alpha: 0.06)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 48, color: scheme.primary.withValues(alpha: 0.65)),
                    const SizedBox(width: 16),
                    Icon(Icons.hardware_outlined, size: 40, color: muted.withValues(alpha: 0.5)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Hali stansiyalar yo\'q',
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Yangi nuqta qo\'shish uchun + tugmasini bosing',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted.withValues(alpha: 0.85), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateMapPainter extends CustomPainter {
  final Color color;
  _EmptyStateMapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.38;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    for (var i = 0; i < 5; i++) {
      final y = cy - r + (2 * r) * (i / 4);
      canvas.drawLine(Offset(cx - r, y), Offset(cx + r, y), paint);
    }
    for (var j = 0; j < 5; j++) {
      final x = cx - r + (2 * r) * (j / 4);
      canvas.drawLine(Offset(x, cy - r), Offset(x, cy + r), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
