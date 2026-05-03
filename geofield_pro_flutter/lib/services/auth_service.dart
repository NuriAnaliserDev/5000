import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/error/app_error.dart';
import '../core/error/error_logger.dart';
import '../core/error/error_handler.dart';

import '../utils/firebase_ready.dart';
import '../core/network/network_executor.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;

  FirebaseAuth? get _auth {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    final auth = _auth;
    if (auth == null) {
      _currentUser = null;
      return;
    }
    _currentUser = auth.currentUser;
    auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
      if (user != null) {
        unawaited(ensureFirestoreUserProfileIfMissing(user));
      }
    });
  }

  static const String _firebaseUnavailable =
      'Bulut tizimi (Firebase) ishlamayapti — faqat mahalliy rejim.';

  /// Ko‘rsatish uchun ism: avvalo [User.displayName], so‘ng email prefiksi.
  static String displayNameFromUser(User user) {
    final d = user.displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'User';
  }

  /// `users/{uid}` bo‘lmasa yaratadi — Firestore qoidalaridagi `isAdmin()` uchun `role` maydoni.
  /// Mavjud hujjatga tegmaydi (faqat yo‘q bo‘lsa).
  static Future<void> ensureFirestoreUserProfileIfMissing(User user) async {
    if (!isFirebaseCoreReady) return;
    final fs = firestoreOrNull;
    if (fs == null) return;
    try {
      final ref = fs.collection('users').doc(user.uid);
      final snap = await NetworkExecutor.execute(
        () => ref.get(),
        actionName: 'Get user profile',
        maxRetries: 2,
      );
      if (snap.exists) return;
      final dn = user.displayName?.trim();
      final em = user.email?.trim();
      
      await NetworkExecutor.execute(
        () => ref.set(
          {
            if (em != null && em.isNotEmpty) 'email': em,
            'displayName':
                (dn != null && dn.isNotEmpty) ? dn : displayNameFromUser(user),
            'role': 'geologist',
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
        actionName: 'Set user profile',
        maxRetries: 2,
      );
    } catch (e, st) {
      ErrorLogger.record(e, st,
          customMessage:
              'AuthService.ensureFirestoreUserProfileIfMissing failed');
    }
  }

  Future<void> login(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw AppError(_firebaseUnavailable, category: ErrorCategory.network);
    }
    try {
      await NetworkExecutor.execute(
        () => auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
        actionName: 'Login',
        maxRetries: 1,
      );
      final u = auth.currentUser;
      if (u != null) await ensureFirestoreUserProfileIfMissing(u);
    } catch (e, st) {
      throw ErrorHandler.process(e, st);
    }
  }

  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw AppError(_firebaseUnavailable, category: ErrorCategory.network);
    }
    try {
      final cred = await NetworkExecutor.execute(
        () => auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
        actionName: 'Register',
        maxRetries: 1,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty && cred.user != null) {
        await cred.user!.updateDisplayName(name);
        await cred.user!.reload();
      }
      final u = auth.currentUser;
      if (u != null) await ensureFirestoreUserProfileIfMissing(u);
    } catch (e, st) {
      throw ErrorHandler.process(e, st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw AppError(_firebaseUnavailable, category: ErrorCategory.network);
    }
    try {
      await NetworkExecutor.execute(
        () => auth.sendPasswordResetEmail(email: email.trim()),
        actionName: 'Reset Password',
        maxRetries: 1,
      );
    } catch (e, st) {
      throw ErrorHandler.process(e, st);
    }
  }

  Future<void> logout() async {
    await _auth?.signOut();
    notifyListeners();
  }

  /// Muvaffaqiyatli kirish/register keyin chaqiring — [SettingsController] ga
  /// oxirgi sessiyani eslatadi. [SplashScreen] oflayn ham bu ma'lumotdan
  /// foydalanib foydalanuvchini darhol dashboardga olib kiradi.
  static Map<String, String?>? authSnapshot(User? user) {
    if (user == null) return null;
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
    };
  }
}
