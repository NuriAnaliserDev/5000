import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/security_provider.dart';
import '../screens/lock_screen.dart';

/// A wrapper widget that manages application lifecycle security.
/// It observes app state changes and handles auto-locking and privacy blurring.
class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityProvider = context.read<SecurityProvider>();
    
    // Safety check: only proceed if security (PIN) is actually set up
    if (!securityProvider.hasPin) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      setState(() {
        _isBackgrounded = true;
      });
      // Force lock if not already locked
      securityProvider.lock();
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isBackgrounded = false;
      });
      _checkLockStatus();
    }
  }

  void _checkLockStatus() {
    final securityProvider = context.read<SecurityProvider>();
    if (securityProvider.isLocked) {
      _showLockScreen();
    }
  }

  Future<void> _showLockScreen() async {
    // Avoid multiple concurrent lock screens
    if (!mounted) return;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const LockScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Privacy Blur Overlay
        if (_isBackgrounded)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Icon(Icons.security_rounded, color: Colors.white, size: 80),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
