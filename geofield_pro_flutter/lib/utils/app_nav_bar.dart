import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_controller.dart';
import 'app_localizations.dart';

/// Pastki navigatsiya: 5 ta slot (Dashboard, Xarita, Kamera, Arxiv, Yana).
/// Xabarlar, admin/sozlamalar va (expert) masshtab — "Yana" ostida.
class AppBottomNavBar extends StatelessWidget {
  final String activeRoute;
  final bool useShellNavigation;
  final void Function(String route)? onShellTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.activeRoute,
    this.useShellNavigation = false,
    this.onShellTabSelected,
  });

  /// Pastki suzuvchi nav + tizim chizig‘i — Snackbar, FAB, TabBarView zaxirasi.
  static double overlayClearanceAboveNav(BuildContext context) {
    final sysBottom = MediaQuery.paddingOf(context).bottom;
    return sysBottom + 86;
  }

  /// Body scroll ro‘yxati oxirida yengil bo‘sh joy (Scaffold body allaqachon nav ustida).
  static double listScrollEndGap(BuildContext context) {
    final sysBottom = MediaQuery.paddingOf(context).bottom;
    return sysBottom + 24;
  }

  static bool _isMoreRoute(String route) {
    return route == '/messages' ||
        route == '/admin' ||
        route == '/scale-assistant';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12);
    final isExpert = context.watch<SettingsController>().expertMode;
    final moreActive = _isMoreRoute(activeRoute);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.hardEdge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: isDark ? 0.78 : 0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(
                      context,
                      icon: Icons.home_rounded,
                      label: context.loc('dashboard'),
                      route: '/dashboard',
                      isActive: activeRoute == '/dashboard',
                      useShellNavigation: useShellNavigation,
                      onShellTabSelected: onShellTabSelected,
                    ),
                    _navItem(
                      context,
                      icon: Icons.map_rounded,
                      label: context.loc('map'),
                      route: '/map',
                      isActive: activeRoute == '/map',
                      useShellNavigation: useShellNavigation,
                      onShellTabSelected: onShellTabSelected,
                    ),
                    _navItem(
                      context,
                      icon: Icons.photo_camera_rounded,
                      label: context.loc('camera'),
                      route: '/camera',
                      isActive: activeRoute == '/camera',
                      useShellNavigation: useShellNavigation,
                      onShellTabSelected: onShellTabSelected,
                    ),
                    _navItem(
                      context,
                      icon: Icons.archive_rounded,
                      label: context.loc('archive'),
                      route: '/archive',
                      isActive: activeRoute == '/archive',
                      useShellNavigation: useShellNavigation,
                      onShellTabSelected: onShellTabSelected,
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
    required bool useShellNavigation,
    required void Function(String route)? onShellTabSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurfaceVariant;
    final activeColor = scheme.primary;
    final iconColor = isActive ? activeColor : inactive;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: label,
          child: Semantics(
            label: label,
            button: true,
            child: InkWell(
              splashColor: activeColor.withValues(alpha: 0.12),
              highlightColor: activeColor.withValues(alpha: 0.06),
              onTap: () {
                if (isActive) return;
                if (useShellNavigation && onShellTabSelected != null) {
                  onShellTabSelected(route);
                  return;
                }
                Navigator.of(context).pushReplacementNamed(route);
              },
              child: SizedBox(
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withValues(alpha: 0.2)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurfaceVariant;
    final activeColor = scheme.primary;
    final color = isActive ? activeColor : inactive;
    final moreLabel = context.loc('nav_more');
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: moreLabel,
          child: Semantics(
            label: moreLabel,
            button: true,
            child: InkWell(
              splashColor: activeColor.withValues(alpha: 0.12),
              highlightColor: activeColor.withValues(alpha: 0.06),
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
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withValues(alpha: 0.2)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.more_horiz_rounded,
                            color: color, size: 24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        moreLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
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
        ),
      ),
    );
  }
}
