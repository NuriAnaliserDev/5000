import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/hive_db.dart';
import '../services/settings_controller.dart';
import '../services/user_flags_service.dart';
import '../l10n/app_strings.dart';
import '../utils/wmm/wmm_model.dart';
import '../utils/firebase_ready.dart';
import '../core/diagnostics/app_timeouts.dart';
import '../core/diagnostics/startup_telemetry.dart';
import '../core/diagnostics/production_diagnostics.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bootstrap();
      }
    });
  }

  GeoFieldStrings? get _loc => GeoFieldStrings.of(context);

  String _s(String? val, String fallback) => val ?? fallback;

  Future<void> _bootstrap() async {
    StartupTelemetry.milestone('splash_bootstrap_begin');
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      setState(() {
        _progress = 0.3;
        _statusLabel = _s(_loc?.splash_status_firebase, 'Firebase tekshirilmoqda...');
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;

      if (isFirebaseCoreReady) {
        try {
          setState(() {
            _statusLabel = _s(_loc?.splash_status_session, 'Sessiya tiklanmoqda...');
          });
          await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(AppTimeouts.splashAuthStateFirstEvent);
        } catch (_) {
          // Token / tarmoq sekin — mahalliy rejimga o‘tamiz
        }
        if (!mounted) return;
        try {
          for (var i = 0; i < 100; i++) {
            if (FirebaseAuth.instance.currentUser != null) break;
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _progress = 0.5;
        _statusLabel = _s(_loc?.splash_status_local_db, 'Mahalliy ma\'lumotlar bazasi...');
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      if (!Hive.isBoxOpen(HiveDb.stationsBox)) {
        throw StateError(_s(_loc?.splash_error_local_db, 'Mahalliy ma\'lumotlar bazasi ochilmadi'));
      }

      setState(() {
        _progress = 0.7;
        _statusLabel = _s(_loc?.splash_status_offline_tiles, 'Xarita keshi...');
      });
      if (!kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      if (!mounted) return;
      setState(() {
        _progress = 0.9;
        _statusLabel = _s(_loc?.splash_status_wmm, 'Magnit modeli...');
      });
      try {
        WmmModel.embedded().declination(
          lat: 41.0,
          lng: 69.0,
          date: DateTime.now(),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('WMM declination: $e');
        }
      }

      setState(() {
        _progress = 0.95;
        _statusLabel = _s(_loc?.splash_status_profile, 'Profil yuklanmoqda...');
      });
      if (mounted) {
        try {
          await _syncOnboardingForLoggedInUser()
              .timeout(AppTimeouts.splashFirestoreOnboardingSync);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Onboarding sync atlandi: $e');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _statusLabel = _s(_loc?.splash_status_ready, 'Tayyor!');
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;
      StartupTelemetry.milestone('splash_complete');
      unawaited(ProductionDiagnostics.memoryCheckpoint('splash_before_nav'));
      _goNext();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Splash bootstrap: $e\n$st');
      }
      unawaited(
        ProductionDiagnostics.failure(
          'splash_bootstrap',
          data: {'error': e.toString()},
        ),
      );
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
        context.go(AppRouter.onboarding);
      } else {
        context.go(AppRouter.dashboard);
      }
      return;
    }

    // Firebase hali joriy foydalanuvchini tiklay olmadi (internet sekin yoki
    // tokenni yuklashda kechikish). Agar oxirgi sessiya Hive'da eslab qolingan
    // bo‘lsa — foydalanuvchi allaqachon kirgan, uni dashboardga qaytaramiz.
    // Firebase keyin o‘zi tiklanadi (authStateChanges orqali).
    if (rememberedUid != null && rememberedUid.isNotEmpty) {
      if (user == null) {
        unawaited(
          ProductionDiagnostics.session(
            'remembered_uid_dashboard',
            data: {'uid_len': rememberedUid.length},
          ),
        );
      }
      final name = settings.lastAuthName;
      if (name != null && name.isNotEmpty && settings.currentUserName != name) {
        settings.setLocalDisplayName(name);
      }
      if (settings.isFirstRun) {
        context.go(AppRouter.onboarding);
      } else {
        context.go(AppRouter.dashboard);
      }
      return;
    }

    context.go(AppRouter.auth);
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
