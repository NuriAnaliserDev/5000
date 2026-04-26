import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/desktop/desktop_shell.dart';
import '../screens/web/web_dashboard_main.dart';
import '../screens/web/web_login_screen.dart';
import '../services/auth_service.dart';

bool _isDesktopExe() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Web: dashboard login. Desktop (.exe): [DesktopShell]. Mobil: [DashboardScreen].
class PlatformGate extends StatelessWidget {
  const PlatformGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final auth = context.watch<AuthService>();
      return auth.isAuthenticated
          ? const WebDashboardMain()
          : const WebLoginScreen();
    }

    if (_isDesktopExe()) {
      final auth = context.watch<AuthService>();
      return auth.isAuthenticated
          ? const DesktopShell()
          : const AuthScreen();
    }

    return const DashboardScreen();
  }
}
