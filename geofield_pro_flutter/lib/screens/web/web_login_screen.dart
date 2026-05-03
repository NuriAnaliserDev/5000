import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/settings_controller.dart';
import '../../core/error/error_handler.dart';
import 'web_dashboard_main.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _register = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMsg;

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

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Email va parolni kiriting.');
      return;
    }
    if (_register) {
      if (password.length < 6) {
        setState(() => _errorMsg = 'Parol kamida 6 belgi.');
        return;
      }
      if (password != _confirmCtrl.text) {
        setState(() => _errorMsg = 'Parollar mos emas.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final auth = context.read<AuthService>();
    final settings = context.read<SettingsController>();
    try {
      if (_register) {
        await auth.register(
          email,
          password,
          displayName:
              _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        );
      } else {
        await auth.login(email, password);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ErrorHandler.show(context, e, st);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      settings.setLocalDisplayName(AuthService.displayNameFromUser(user));
    }
    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WebDashboardMain()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1565C0), width: 2),
                        ),
                        child: const Icon(Icons.terrain,
                            size: 40, color: Color(0xFF42A5F5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GeoField Pro N',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dashboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF42A5F5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: [!_register, _register],
                    onPressed: (i) => setState(() {
                      _register = i == 1;
                      _errorMsg = null;
                    }),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white70,
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF1565C0).withValues(alpha: 0.4),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Kirish'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Ro\'yxat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_register) ...[
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Ism (ixtiyoriy)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _passwordCtrl,
                    label: 'Parol',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _confirmCtrl,
                      label: 'Parolni tasdiqlang',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                    ),
                  ],
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF1565C0).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _register
                                  ? 'RO\'YXATDAN O\'TISH'
                                  : 'TIZIMGA KIRISH',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aurum Global Group © 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white12, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
