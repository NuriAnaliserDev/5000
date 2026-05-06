import 'package:flutter/material.dart';

import '../utils/app_localizations.dart';
import '../utils/app_nav_bar.dart';
import '../widgets/common/stitch_screen_background.dart';
import 'admin/admin_screen_body.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surf = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : surf,
      extendBody: isDark,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : surf,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(context.loc('admin_full_title')),
      ),
      body: isDark
          ? const Stack(
              fit: StackFit.expand,
              children: [
                StitchScreenBackground(),
                AdminScreenBody(),
              ],
            )
          : const AdminScreenBody(),
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/admin'),
    );
  }
}
