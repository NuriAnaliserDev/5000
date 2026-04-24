import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _currentUser = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

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

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Bunday foydalanuvchi topilmadi.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email yoki parol xato.';
        case 'too-many-requests':
          return 'Juda ko\'p urinish. Bir oz kuting.';
        case 'network-request-failed':
          return 'Internet aloqasi yo\'q.';
        case 'internal-error':
        case 'unknown':
        case 'operation-not-allowed':
          if (_isAuthConfigOrRecaptchaError(e)) {
            return _firebaseAuthConfigHint();
          }
          return e.message ?? 'Tizimga kirishda xatolik yuz berdi.';
        default:
          if (_isAuthConfigOrRecaptchaError(e)) {
            return _firebaseAuthConfigHint();
          }
          return e.message ?? 'Tizimga kirishda xatolik yuz berdi.';
      }
    } catch (e) {
      return 'Kutilmagan xatolik: ${e.toString()}';
    }
  }

  Future<String?> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty && cred.user != null) {
        await cred.user!.updateDisplayName(name);
        await cred.user!.reload();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Bu email allaqachon ro\'yxatdan o\'tgan.';
        case 'invalid-email':
          return 'Email noto\'g\'ri.';
        case 'weak-password':
          return 'Parol juda zaif (kamida 6 belgi).';
        case 'network-request-failed':
          return 'Internet aloqasi yo\'q.';
        case 'internal-error':
        case 'unknown':
        case 'operation-not-allowed':
          if (_isAuthConfigOrRecaptchaError(e)) {
            return _firebaseAuthConfigHint();
          }
          return e.message ?? 'Ro\'yxatdan o\'tishda xatolik.';
        default:
          if (_isAuthConfigOrRecaptchaError(e)) {
            return _firebaseAuthConfigHint();
          }
          return e.message ?? 'Ro\'yxatdan o\'tishda xatolik.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Bu email ro\'yxatdan o\'tmagan.';
      }
      return e.message ?? 'Xatolik yuz berdi.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  static bool _isAuthConfigOrRecaptchaError(FirebaseAuthException e) {
    final m = (e.message ?? '').toLowerCase();
    return m.contains('configuration_not_found') ||
        m.contains('recaptcha') ||
        m.contains('internal error has occurred') ||
        m.contains('appcheck');
  }

  static String _firebaseAuthConfigHint() {
    return "Firebase Android uchun Web client ID (default_web_client_id) qo'shilmagan. "
        "android/firebase_secrets.properties.example faylida yo'riqnomaga qarang, "
        "so'zlangan kalitni qo'ying yoki muhit o'zgaruvchisidan FIREBASE_DEFAULT_WEB_CLIENT_ID bering.";
  }

  void devLogin() {
    assert(() {
      debugPrint('[DEV] devLogin() chaqirildi — faqat debug mode');
      return true;
    }());
  }
}
