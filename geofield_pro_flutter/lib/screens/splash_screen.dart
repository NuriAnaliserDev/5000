import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/hive_db.dart';
import '../services/settings_controller.dart';
import '../services/user_flags_service.dart';
import '../utils/wmm/wmm_model.dart';
import '../utils/firebase_ready.dart';
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
        setState(() {
          _statusLabel = 'Sessiya...';
        });
        // Saqlangan kirish: ba'zida [currentUser] keyinroq to'ldiriladi; authState
        // birinchi hodisasini 8 sekundgacha kutamiz (internet sekin bo‘lishi mumkin).
        try {
          await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          // tarmoq yoki vaqt — davom etamiz
        }
        // Ba'zi qurilmalarda birinchi hodisa null, keyin saqlangan foydalanuvchi paydo bo‘ladi.
        // Jami ~3 sekund kutamiz: 100 * 30ms.
        for (int i = 0; i < 100; i++) {
          if (FirebaseAuth.instance.currentUser != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
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
        _progress = 0.95;
        _statusLabel = 'Profil...';
      });
      if (mounted) {
        await _syncOnboardingForLoggedInUser();
      }

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

  /// Tizimda allaqachon sessiya bo‘lsa — Firestore’dan «onboarding o‘tgan» sozlamasini olish.
  Future<void> _syncOnboardingForLoggedInUser() async {
    if (!isFirebaseCoreReady) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final completed = await UserFlagsService.getOnboardingCompleted(u.uid);
    if (!mounted) return;
    final settings = context.read<SettingsController>();
    if (completed == true) {
      settings.isFirstRun = false;
    } else if (completed == null) {
      // Eski foydalanuvchi, hujjat yo‘q — qayta tanishtirish qilmaymiz, bulutga belgi qo‘yamiz
      settings.isFirstRun = false;
      await UserFlagsService.setOnboardingCompleted(u.uid, true);
    }
  }

  void _goNext() {
    final settings = context.read<SettingsController>();
    User? user;
    if (isFirebaseCoreReady) {
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
    }
    final rememberedUid = settings.lastAuthUid;

    if (user != null) {
      final name = AuthService.displayNameFromUser(user);
      if (settings.currentUserName != name) {
        settings.setLocalDisplayName(name);
      }
      settings.rememberAuth(
        uid: user.uid,
        email: user.email,
        displayName: name,
      );
      if (settings.isFirstRun) {
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
      return;
    }

    // Firebase hali joriy foydalanuvchini tiklay olmadi (internet sekin yoki
    // tokenni yuklashda kechikish). Agar oxirgi sessiya Hive'da eslab qolingan
    // bo‘lsa — foydalanuvchi allaqachon kirgan, uni dashboardga qaytaramiz.
    // Firebase keyin o‘zi tiklanadi (authStateChanges orqali).
    if (rememberedUid != null && rememberedUid.isNotEmpty) {
      final name = settings.lastAuthName;
      if (name != null &&
          name.isNotEmpty &&
          settings.currentUserName != name) {
        settings.setLocalDisplayName(name);
      }
      if (settings.isFirstRun) {
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
      return;
    }

    Navigator.pushReplacementNamed(context, AppRouter.auth);
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
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
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
