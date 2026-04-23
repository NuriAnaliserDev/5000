import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/dashboard_screen.dart';
import '../screens/desktop/desktop_shell.dart';
import '../screens/web/web_dashboard_main.dart';
import '../screens/web/web_login_screen.dart';
import '../services/auth_service.dart';

/// Platformaga qarab asosiy ekranni tanlaydi:
/// * Web → [WebDashboardMain] (agar autentifikatsiyadan o‘tgan bo‘lsa).
/// * Windows / macOS / Linux → [DesktopShell].
/// * Android / iOS → [DashboardScreen] (mobil).
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

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return const DesktopShell();
    }

    return const DashboardScreen();
  }
}
