import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_controller.dart';
import 'components/web_sidebar.dart';
import 'web_map_screen.dart';
import 'web_reports_screen.dart';
import 'web_analytics_screen.dart';
import 'web_settings_screen.dart';

class WebDashboardMain extends StatefulWidget {
  const WebDashboardMain({super.key});

  @override
  State<WebDashboardMain> createState() => _WebDashboardMainState();
}

class _WebDashboardMainState extends State<WebDashboardMain> {
  int _selectedIndex = 0;

  // 4 ta ekran — RC bo'limi olib tashlandi, Reports endi 3 tabli
  final List<Widget> _screens = [
    const WebMapScreen(),
    const WebReportsScreen(),
    const WebAnalyticsScreen(),
    const WebSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final isDark = themeCtrl.mode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5),
      body: Row(
        children: [
          WebSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  // ValueKey — AnimatedSwitcher to'g'ri animatsiya qilishi uchun
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
