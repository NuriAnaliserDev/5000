import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/security_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _isError = false;

  void _handleKeyPress(String key) {
    HapticFeedback.lightImpact();
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
        _isError = false;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _handleDelete() {
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.unlockWithPin(_pin);

    if (success) {
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _isError = true;
      });
    }
  }

  Future<void> _handleBiometric() async {
    final securityProvider = context.read<SecurityProvider>();
    final success = await securityProvider.unlockWithBiometrics();
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometrics if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleBiometric();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_rounded,
                    size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                const Text(
                  'GeoField Pro N Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isError
                      ? 'Noto\'g\'ri PIN. Qayta urining.'
                      : 'PIN-kodni kiriting',
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.white60,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    bool filled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            filled ? colorScheme.secondary : Colors.transparent,
                        border: Border.all(
                          color:
                              filled ? colorScheme.secondary : Colors.white30,
                          width: 2,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: colorScheme.secondary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 60),

                // PIN Pad
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index == 9) {
                          // Biometric Button
                          return _buildPadButton(
                            icon: Icons.fingerprint_rounded,
                            onTap: _handleBiometric,
                          );
                        } else if (index == 10) {
                          return _buildPadButton(
                              label: '0', onTap: () => _handleKeyPress('0'));
                        } else if (index == 11) {
                          // Delete Button
                          return _buildPadButton(
                            icon: Icons.backspace_outlined,
                            onTap: _handleDelete,
                          );
                        } else {
                          String val = (index + 1).toString();
                          return _buildPadButton(
                              label: val, onTap: () => _handleKeyPress(val));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(
      {String? label, IconData? icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
