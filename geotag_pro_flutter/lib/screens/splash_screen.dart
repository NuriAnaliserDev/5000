import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/hive_db.dart';
import '../services/settings_controller.dart';
import '../utils/wmm/wmm_model.dart';
import 'error_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;
  String _statusLabel = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      setState(() {
        _progress = 0.3;
        _statusLabel = 'Firebase init...';
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (Firebase.apps.isNotEmpty) {
        Firebase.app();
      }

      setState(() {
        _progress = 0.5;
        _statusLabel = 'Local DB...';
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!Hive.isBoxOpen(HiveDb.stationsBox)) {
        throw StateError('Mahalliy baza ochildi — qayta urinib ko‘ring');
      }

      setState(() {
        _progress = 0.7;
        _statusLabel = 'Offline tiles...';
      });
      if (!kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      setState(() {
        _progress = 0.9;
        _statusLabel = 'WMM model...';
      });
      WmmModel.embedded().declination(
        lat: 41.0,
        lng: 69.0,
        date: DateTime.now(),
      );

      setState(() {
        _progress = 1.0;
        _statusLabel = 'Tayyor';
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;
      _goNext();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Splash bootstrap: $e\n$st');
      }
      if (mounted) {
        setState(() {
          _error = e is Error ? e.toString() : '$e';
        });
      }
    }
  }

  void _goNext() {
    final settings = context.read<SettingsController>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user != null) {
      final name = AuthService.displayNameFromUser(user);
      if (settings.currentUserName != name) {
        settings.setLocalDisplayName(name);
      }
    }
    if (settings.isFirstRun) {
      Navigator.pushReplacementNamed(context, AppRouter.onboarding);
    } else if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRouter.auth);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorScreen(
        message: _error!,
        onRetry: _bootstrap,
      );
    }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
