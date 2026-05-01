import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// `Firebase.initializeApp` muvaffaqiyatli bo‘lganda `true`.
bool get isFirebaseCoreReady {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Firestore mavjud bo‘lmasa `null` (ilova yiqilmaydi).
FirebaseFirestore? get firestoreOrNull {
  if (!isFirebaseCoreReady) return null;
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}

/// [runAppBootstrap] dan beriladi — Firebase bulut ishlamasa `isCloudEnabled == false`.
class FirebaseBootstrapState {
  const FirebaseBootstrapState({required this.isCloudEnabled});
  final bool isCloudEnabled;
}
