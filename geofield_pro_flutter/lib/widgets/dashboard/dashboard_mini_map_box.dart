import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/main_tab_navigation.dart';
/// Kichik xarita ko'rinishi — hozirgi joylashuvni ko'rsatadi.
///
/// Faqat [userLatLng] + [mapStyle] o'zgarishiga bog'liq (Selector
/// [DashboardScreen]da qo'llanadi).
class DashboardMiniMapBox extends StatelessWidget {
  final LatLng? userLatLng;
  final String mapStyle;
  final bool isDark;

  const DashboardMiniMapBox({
    super.key,
    required this.userLatLng,
    required this.mapStyle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pos = userLatLng;
    final center = pos == null
        ? const LatLng(41.3111, 69.2797) // Toshkent default
        : LatLng(pos.latitude, pos.longitude);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: () => MainTabNavigation.openMap(context),
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: pos == null ? 6 : 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // Read-only preview
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl(mapStyle),
                  userAgentPackageName: 'com.geofield.pro',
                  tileBuilder: isDark ? _darkTileBuilder : null,
                ),
                if (pos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 30,
                        height: 30,
                        child: const _GpsPulse(),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _OverlayChip(
                icon: Icons.open_in_full_rounded,
                label: 'To\'liq xarita',
                isDark: isDark,
              ),
            ),
            if (pos == null)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x99000000),
                  child: Center(
                    child: Text(
                      'GPS kutilmoqda…',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _tileUrl(String style) {
    switch (style) {
      case 'osm':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'opentopomap':
      default:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  static Widget _darkTileBuilder(BuildContext _, Widget tile, TileImage __) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.8, 0, 0, 0, 255,
        0, -0.8, 0, 0, 255,
        0, 0, -0.8, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

class _OverlayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xCC181818) : const Color(0xCCFFFFFF);
    final fg = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

class _GpsPulse extends StatefulWidget {
  const _GpsPulse();
  @override
  State<_GpsPulse> createState() => _GpsPulseState();
}

class _GpsPulseState extends State<_GpsPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return CustomPaint(
          painter: _PulsePainter(t),
          size: const Size(30, 30),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double t;
  _PulsePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Outer pulse ring
    final ringR = 4 + 12 * t;
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..color = const Color(0xFF1976D2).withValues(alpha: (1 - t) * 0.6),
    );
    // Core dot
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF1976D2));
    canvas.drawCircle(
      c,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}
