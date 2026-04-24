import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Foydalanuvchi sozlamalari (Firestore `users/{uid}`) — qayta o‘rnatganda onboarding.
/// Firestore: `allow read, write: if request.auth != null && request.auth.uid == userId;`
/// (hujjat ID = Firebase UID)
class UserFlagsService {
  static final _col = FirebaseFirestore.instance.collection('users');

  static Future<bool?> getOnboardingCompleted(String uid) async {
    try {
      final d = await _col.doc(uid).get();
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
    try {
      await _col.doc(uid).set(
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
