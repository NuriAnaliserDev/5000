import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import '../core/di/dependency_injection.dart';
import '../screens/error_screen.dart';
import '../services/location_service.dart';
import 'global_navigator.dart';
import '../core/diagnostics/startup_telemetry.dart';
import '../core/diagnostics/production_diagnostics.dart';

/// [main] dan so‘ng birinchi `runApp` — [runAppBootstrap] muvaffaqiyatsiz
/// bo‘lsa [ErrorScreen], muvaffaqiyatda ildiz widget.
class AppBootstrapShell extends StatefulWidget {
  const AppBootstrapShell({super.key});

  @override
  State<AppBootstrapShell> createState() => _AppBootstrapShellState();
}

class _AppBootstrapShellState extends State<AppBootstrapShell> {
  final AppLifecycleDiagnosticsObserver _lifecycle =
      AppLifecycleDiagnosticsObserver(
    onResumed: () async {
      try {
        await sl<LocationService>().onApplicationResumed();
      } catch (_) {}
    },
  );

  String? _error;
  Object? _cause;
  StackTrace? _errorStack;
  Widget? _root;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycle);
    StartupTelemetry.milestone('bootstrap_shell_mount');
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycle);
    super.dispose();
  }

  Future<void> _start() async {
    if (kDebugMode) {
      debugPrint('AppBootstrap: attempting initialization...');
    }
    setState(() {
      _error = null;
      _cause = null;
      _errorStack = null;
    });

    StartupTelemetry.milestone('bootstrap_shell_start');

    final r = await runAppBootstrap();
    if (!mounted) return;

    if (r is AppBootstrapSuccess) {
      setState(() {
        _root = r.rootWidget;
        _error = null;
      });
      StartupTelemetry.milestone('bootstrap_shell_root_ready');
      unawaited(ProductionDiagnostics.memoryCheckpoint('shell_root_ready'));
    } else if (r is AppBootstrapFailure) {
      debugPrint('AppBootstrap: FAILED: ${r.userMessage}');
      if (r.cause != null) {
        debugPrint('Cause: ${r.cause}');
      }
      if (r.stackTrace != null) {
        debugPrint('Stack: ${r.stackTrace}');
      }
      setState(() {
        _error = r.userMessage;
        _cause = r.cause;
        _errorStack = r.stackTrace;
        _root = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_root != null) {
      return _root!;
    }
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(
          message: _formatErrorMessage(),
          onRetry: _start,
        ),
      );
    }
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.terrain,
                    size: 72,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(
                  'Geofield Pro yuklanmoqda…',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatErrorMessage() {
    final buf = StringBuffer(_error ?? 'Noma’lum xato');
    if (kDebugMode && _errorStack != null) {
      buf
        ..writeln()
        ..writeln('---')
        ..writeln(_errorStack);
    } else if (kDebugMode && _cause != null) {
      buf
        ..writeln()
        ..writeln('---')
        ..writeln(_cause);
    }
    return buf.toString();
  }
}
