import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'hive_db.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  /// Haqiqiy autentifikatsiya: faqat Firebase foydalanuvchisi bo'lganda true.
  /// Dev bypass yo'q — bu production-safe.
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        final box = Hive.box(HiveDb.settingsBox);
        box.put('currentUserName', credential.user!.email?.split('@').first ?? 'User');
        box.put('currentUserRole', 'Geologist'); // Default role
      }
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
        default:
          return e.message ?? 'Tizimga kirishda xatolik yuz berdi.';
      }
    } catch (e) {
      return 'Kutilmagan xatolik: ${e.toString()}';
    }
  }

  /// Parolni tiklash uchun email yuboradi.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // muvaffaqiyat
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
    final box = Hive.box(HiveDb.settingsBox);
    box.delete('currentUserName');
    box.delete('currentUserRole');
    notifyListeners();
  }

  /// Debug maqsadida faqat assert da ishlaydi — production'da compile out bo'ladi.
  void devLogin() {
    assert(() {
      debugPrint('[DEV] devLogin() chaqirildi — faqat debug mode');
      return true;
    }());
  }
}
