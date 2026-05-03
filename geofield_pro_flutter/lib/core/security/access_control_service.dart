import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../error/app_error.dart';
import '../error/error_logger.dart';

enum UserRole {
  geologist,
  geologistSenior,
  admin,
  unknown,
}

class AccessControlService extends ChangeNotifier {
  UserRole _currentRole = UserRole.unknown;
  StreamSubscription? _roleSubscription;

  UserRole get currentRole => _currentRole;

  bool get isAdmin => _currentRole == UserRole.admin;
  bool get isSeniorOrAdmin =>
      _currentRole == UserRole.admin ||
      _currentRole == UserRole.geologistSenior;

  AccessControlService() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _currentRole = UserRole.unknown;
        _roleSubscription?.cancel();
        notifyListeners();
      } else {
        _listenToUserRole(user.uid);
      }
    });
  }

  void _listenToUserRole(String uid) {
    _roleSubscription?.cancel();
    _roleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        _currentRole = UserRole.unknown;
      } else {
        final roleStr = snap.data()?['role'] as String?;
        switch (roleStr) {
          case 'admin':
            _currentRole = UserRole.admin;
            break;
          case 'geologist_senior':
            _currentRole = UserRole.geologistSenior;
            break;
          case 'geologist':
            _currentRole = UserRole.geologist;
            break;
          default:
            _currentRole = UserRole.unknown;
        }
      }
      notifyListeners();
    }, onError: (e, st) {
      ErrorLogger.record(e, st, customMessage: 'Error listening to user role');
    });
  }

  /// Throws AppError if user is not authenticated.
  void requireAuth() {
    if (FirebaseAuth.instance.currentUser == null) {
      throw AppError(
          'Ushbu amalni bajarish uchun tizimga kirish talab qilinadi.',
          category: ErrorCategory.auth);
    }
  }

  /// Throws AppError if user is not Admin or Senior.
  void requireSeniorOrAdmin() {
    requireAuth();
    if (!isSeniorOrAdmin) {
      throw AppError(
          "Sizda ushbu amalni bajarish uchun yetarli ruxsat yo'q (Admin yoki Katta Geolog darajasi talab qilinadi).",
          category: ErrorCategory.validation);
    }
  }

  /// Throws AppError if user is not strictly Admin.
  void requireAdmin() {
    requireAuth();
    if (!isAdmin) {
      throw AppError(
          'Ushbu amalni bajarish uchun faqat Admin huquqi talab qilinadi.',
          category: ErrorCategory.validation);
    }
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }
}
