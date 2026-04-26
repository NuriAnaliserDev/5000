import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import '../screens/error_screen.dart';

/// [main] dan so‘ng birinchi `runApp` — [runAppBootstrap] muvaffaqiyatsiz
/// bo‘lsa [ErrorScreen], muvaffaqiyatda ildiz widget.
class AppBootstrapShell extends StatefulWidget {
  const AppBootstrapShell({super.key});

  @override
  State<AppBootstrapShell> createState() => _AppBootstrapShellState();
}

class _AppBootstrapShellState extends State<AppBootstrapShell> {
  String? _error;
  Object? _cause;
  StackTrace? _errorStack;
  Widget? _root;

  @override
  void initState() {
    super.initState();
    _start();
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

    final r = await runAppBootstrap();
    if (!mounted) return;

    if (r is AppBootstrapSuccess) {
      setState(() {
        _root = r.rootWidget;
        _error = null;
      });
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
