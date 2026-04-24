import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/settings_controller.dart';

class AppBottomNavBar extends StatelessWidget {
  final String activeRoute;

  const AppBottomNavBar({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final isExpert = context.watch<SettingsController>().expertMode;

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
                icon: Icons.chat_bubble_rounded,
                label: 'Xabarlar', // Using hardcoded string since string resources might not have 'messages' yet
                route: '/messages',
                isActive: activeRoute == '/messages',
              ),
              _navItem(
                context,
                icon: Icons.map_rounded,
                label: context.loc('map'),
                route: '/map',
                isActive: activeRoute == '/map',
              ),
              if (isExpert)
                _navItem(
                  context,
                  icon: Icons.square_foot_rounded,
                  label: context.loc('scale_short'),
                  route: '/scale-assistant',
                  isActive: activeRoute == '/scale-assistant',
                ),
              _navItem(
                context,
                icon: Icons.history_rounded,
                label: context.loc('archive'),
                route: '/archive',
                isActive: activeRoute == '/archive',
              ),
              _navItem(
                context,
                icon: Icons.settings_rounded,
                label: context.loc('admin'),
                route: '/admin',
                isActive: activeRoute == '/admin',
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
}
