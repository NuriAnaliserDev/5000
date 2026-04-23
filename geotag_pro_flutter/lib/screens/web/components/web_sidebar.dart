import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_controller.dart';

class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsController>();
    final primaryColor = theme.colorScheme.primary;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: primaryColor),
      unselectedIconTheme: IconThemeData(color: isDark ? Colors.white38 : Colors.black38),
      selectedLabelTextStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 11,
      ),
      leading: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/logo.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.terrain, size: 28, color: primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'GeoField Pro N',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          // User info
          if (settings.currentUserName != null) ...[
            const SizedBox(height: 4),
            Text(
              settings.currentUserName!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      // 4 ta navigatsiya elementi (RC bo'limi olib tashlandi)
      destinations: [
        _buildDestination(Icons.map_outlined, Icons.map, 'Jonli Xarita', 0),
        _buildDestination(Icons.inbox_outlined, Icons.inbox, 'Qabulxona', 1),
        _buildDestination(Icons.insights_outlined, Icons.insights, 'Analitika', 2),
        _buildDestination(Icons.settings_outlined, Icons.settings, 'Sozlamalar', 3),
      ],
      trailing: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              tooltip: 'Tizimdan chiqish',
              onPressed: () => context.read<AuthService>().logout(),
            ),
            const Text(
              'Chiqish',
              style: TextStyle(fontSize: 9, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  NavigationRailDestination _buildDestination(
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    int index,
  ) {
    return NavigationRailDestination(
      icon: Icon(unselectedIcon),
      selectedIcon: Icon(selectedIcon),
      label: Text(label),
    );
  }
}
