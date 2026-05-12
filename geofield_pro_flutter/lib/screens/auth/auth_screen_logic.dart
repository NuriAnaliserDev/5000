part of '../auth_screen.dart';

mixin AuthScreenLogicMixin on AuthScreenFields {
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
        _loading = false;
      });
      ErrorHandler.show(context, ErrorMapper.map(e, st));
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
      context.go(AppRouter.onboarding);
    } else {
      settings.isFirstRun = false;
      context.go(AppRouter.dashboard);
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
    try {
      await context.read<AuthService>().sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiklash havolasi emailga yuborildi.'),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _loading = false);
      ErrorHandler.show(context, ErrorMapper.map(e, st));
    }
  }
}
