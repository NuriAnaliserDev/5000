import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/firebase_ready.dart';

/// Foydalanuvchi sozlamalari (Firestore `users/{uid}`) — qayta o‘rnatganda onboarding.
/// Firestore: `allow read, write: if request.auth != null && request.auth.uid == userId;`
/// (hujjat ID = Firebase UID)
class UserFlagsService {
  static CollectionReference<Map<String, dynamic>>? get _usersCol {
    final fs = firestoreOrNull;
    if (fs == null) return null;
    return fs.collection('users');
  }

  static Future<bool?> getOnboardingCompleted(String uid) async {
    final col = _usersCol;
    if (col == null) return null;
    try {
      final d = await col.doc(uid).get();
      if (!d.exists) return null;
      return d.data()?['onboardingCompleted'] as bool?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserFlagsService.getOnboardingCompleted: $e');
      }
      return null;
    }
  }

  static Future<void> setOnboardingCompleted(String uid, bool value) async {
    final col = _usersCol;
    if (col == null) return;
    try {
      await col.doc(uid).set(
        {
          'onboardingCompleted': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserFlagsService.setOnboardingCompleted: $e');
      }
    }
  }
}
