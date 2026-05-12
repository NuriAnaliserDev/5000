import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../services/settings_controller.dart';
import '../services/user_flags_service.dart';
import '../core/error/error_handler.dart';
import '../core/error/error_mapper.dart';

part 'auth/auth_screen_fields.dart';
part 'auth/auth_screen_logic.dart';
part 'auth/auth_screen_state.dart';

/// Email + parol: kirish va ro‘yxatdan o‘tish (Firebase Auth).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
