import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_controller.dart';
import 'app_localizations.dart';

/// Pastki navigatsiya: 5 ta slot (Dashboard, Xarita, Kamera, Arxiv, Yana).
/// Xabarlar, admin/sozlamalar va (expert) masshtab — "Yana" ostida.
class AppBottomNavBar extends StatelessWidget {
  final String activeRoute;

  const AppBottomNavBar({super.key, required this.activeRoute});

  static bool _isMoreRoute(String route) {
    return route == '/messages' ||
        route == '/admin' ||
        route == '/scale-assistant';
  }

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final isExpert = context.watch<SettingsController>().expertMode;
    final moreActive = _isMoreRoute(activeRoute);

    return Container(
      color: surf,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context,
                icon: Icons.grid_view_rounded,
                label: context.loc('dashboard'),
                route: '/dashboard',
                isActive: activeRoute == '/dashboard',
              ),
              _navItem(
                context,
                icon: Icons.map_rounded,
                label: context.loc('map'),
                route: '/map',
                isActive: activeRoute == '/map',
              ),
              _navItem(
                context,
                icon: Icons.photo_camera_rounded,
                label: context.loc('camera'),
                route: '/camera',
                isActive: activeRoute == '/camera',
              ),
              _navItem(
                context,
                icon: Icons.history_rounded,
                label: context.loc('archive'),
                route: '/archive',
                isActive: activeRoute == '/archive',
              ),
              _moreItem(
                context,
                isExpert: isExpert,
                isActive: moreActive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool isActive = false,
  }) {
    final color = isActive ? const Color(0xFF1976D2) : Colors.grey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isActive) return;
            Navigator.of(context).pushReplacementNamed(route);
          },
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moreItem(
    BuildContext context, {
    required bool isExpert,
    required bool isActive,
  }) {
    final color = isActive ? const Color(0xFF1976D2) : Colors.grey;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_rounded),
                        title: Text(context.loc('nav_messages')),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context)
                              .pushReplacementNamed('/messages');
                        },
                      ),
                      if (isExpert)
                        ListTile(
                          leading: const Icon(Icons.square_foot_rounded),
                          title: Text(context.loc('scale_short')),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context)
                                .pushReplacementNamed('/scale-assistant');
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.settings_rounded),
                        title: Text(context.loc('admin')),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context)
                              .pushReplacementNamed('/admin');
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz_rounded, color: color),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.loc('nav_more'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
