import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/settings_controller.dart';
import '../services/user_flags_service.dart';

/// Email + parol: kirish va ro‘yxatdan o‘tish (Firebase Auth).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _register = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final auth = context.read<AuthService>();
    final settings = context.read<SettingsController>();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email va parolni kiriting.');
      return;
    }
    if (_register) {
      if (password != _confirmCtrl.text) {
        setState(() => _error = 'Parollar mos kelmaydi.');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = 'Parol kamida 6 belgi bo‘lsin.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final err = _register
        ? await auth.register(
            email,
            password,
            displayName:
                _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          )
        : await auth.login(email, password);

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      settings.setLocalDisplayName(AuthService.displayNameFromUser(user));
      settings.rememberAuth(
        uid: user.uid,
        email: user.email,
        displayName: AuthService.displayNameFromUser(user),
      );
    }
    HapticFeedback.lightImpact();
    setState(() => _loading = false);

    if (user == null) return;

    final completed = await UserFlagsService.getOnboardingCompleted(user.uid);
    if (!mounted) return;

    final showOnboarding =
        _register ? (completed != true) : (completed == false);

    if (showOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
    } else {
      settings.isFirstRun = false;
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Parolni tiklash uchun email kiriting.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthService>().sendPasswordReset(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiklash havolasi emailga yuborildi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSurf = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Hero(
                    tag: 'app_logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'GEOFIELD PRO',
                    style: TextStyle(
                      color: primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _register ? 'RO\'YXATDAN O\'TISH' : 'TIZIMGA KIRISH',
                    style: TextStyle(
                      color: onSurf.withValues(alpha: 0.55),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ToggleButtons(
                    isSelected: [!_register, _register],
                    onPressed: (i) {
                      setState(() {
                        _register = i == 1;
                        _error = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 88),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Kirish'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Ro\'yxat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_register) ...[
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ism (ixtiyoriy)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Parolni tasdiqlang',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _register ? 'RO\'YXATDAN O\'TISH' : 'KIRISH',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  if (!_register) ...[
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Parolni unutdingizmi?'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
