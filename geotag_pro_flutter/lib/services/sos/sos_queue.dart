import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../security/encryption_manager.dart';

/// SOS signallari uchun offline queue.
///
/// Internet yo‘q bo‘lsa, signal Hive box'ga saqlanadi va ulanish paydo
/// bo‘lgan zahoti avtomatik yuboriladi. Shuningdek, `flushNow()` orqali
/// qo‘lda flush qilish mumkin.
class SosQueue {
  SosQueue._();

  static const String boxName = 'sos_queue';
  static Box<Map>? _box;
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  static Future<Box<Map>> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    // Sensitive: GPS + ism shifrlanadi (AES-256, kalit Keystore/Keychain'da).
    try {
      final cipher = await EncryptionManager.cipher();
      _box = await Hive.openBox<Map>(boxName, encryptionCipher: cipher);
    } catch (e) {
      debugPrint('SosQueue: encrypted open failed, falling back: $e');
      _box = await Hive.openBox<Map>(boxName);
    }
    return _box!;
  }

  /// Background flushing'ni ishga tushirish. Qayta chaqirilsa duplicate yo‘q.
  static Future<void> startAutoFlush() async {
    _sub ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        tryFlush();
      }
    });
    // Start-up paytida ham urinib ko‘ramiz.
    await tryFlush();
  }

  /// Signalni queue'ga qo‘shish (offline xavfsiz).
  static Future<void> enqueue({
    required String senderUid,
    required String senderName,
    required double lat,
    required double lng,
  }) async {
    final box = await _openBox();
    await box.add({
      'senderUid': senderUid,
      'senderName': senderName,
      'lat': lat,
      'lng': lng,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Queue'dagi barcha elementlarni yuborishga urinish. Agar yuborilsa,
  /// local nusxa o‘chiriladi.
  static Future<int> tryFlush() async {
    final box = await _openBox();
    if (box.isEmpty) return 0;

    final online = await _hasConnection();
    if (!online) return 0;

    var sent = 0;
    final keys = box.keys.toList();
    for (final key in keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final entry = Map<String, dynamic>.from(raw);
        await FirebaseFirestore.instance.collection('emergency_signals').add({
          'senderUid': entry['senderUid'],
          'senderName': entry['senderName'],
          'lat': entry['lat'],
          'lng': entry['lng'],
          'timestamp': FieldValue.serverTimestamp(),
          'isActive': true,
          'clientCreatedAt': entry['createdAt'],
        });
        await box.delete(key);
        sent++;
      } catch (e) {
        debugPrint('SosQueue.flush error: $e');
        break; // keyingi urinishda qayta sinab ko‘ramiz
      }
    }
    return sent;
  }

  /// Queue'da hozirda nechta signal borligi.
  static Future<int> pendingCount() async {
    final box = await _openBox();
    return box.length;
  }

  static Future<bool> _hasConnection() async {
    try {
      final res = await Connectivity().checkConnectivity();
      return res.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
