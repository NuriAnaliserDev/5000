import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Reduced delay for fast dashboard access as requested
    await Future.delayed(const Duration(milliseconds: 500), () {});
    if (mounted) {
      final settings = context.read<SettingsController>();
      
      // Auto-assign default role if missing to bypass hierarchy selection for now
      if (settings.currentUserRole == null) {
        settings.login('Bosh Geolog', 'Admin User');
      }

      if (settings.isFirstRun) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Now that we have a default role, we always go to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/logo.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
    );
  }
}
