part of '../auth_screen.dart';

mixin AuthScreenFields on State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _register = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
}
