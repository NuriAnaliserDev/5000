import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'sos/sos_queue.dart';
import '../utils/firebase_ready.dart';

/// SMS fallback hook — `url_launcher` bilan to‘ldiriladi (ilova init'ida
/// o‘rnatiladi). Qiymat: `sms:<number>?body=<url-encoded>` URIni ochadigan
/// funksiya. `null` bo‘lsa SMS fallback o‘chirilgan hisoblanadi.
typedef SosSmsHandler = Future<void> Function(Uri smsUri);

class EmergencySignal {
  final String id;
  final String senderUid;
  final String senderName;
  final LatLng position;
  final DateTime timestamp;
  final bool isActive;

  EmergencySignal({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.position,
    required this.timestamp,
    required this.isActive,
  });

  factory EmergencySignal.fromMap(Map<String, dynamic> map, String id) {
    return EmergencySignal(
      id: id,
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      position: LatLng(map['lat'] ?? 0.0, map['lng'] ?? 0.0),
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

/// SOS xizmati — onlayn bo‘lganda darhol yuboradi, aks holda
/// [SosQueue] orqali offline saqlaydi va ulanish paydo bo‘lgach yuboradi.
///
/// Shuningdek, [smsFallback] = `true` bo‘lsa, SMS orqali ham signal
/// yuborishga uriniladi (url_launcher + `sms:` sxema).
class SosService extends ChangeNotifier {
  FirebaseFirestore? get _firestore => firestoreOrNull;
  FirebaseAuth? get _auth {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Tashqi chaqiruv uchun (masalan admin-panel yoki status widget).
  bool lastSendQueued = false;

  /// Ayni paytda faol bo‘lgan, ushbu qurilmadan yuborilgan SOS hujjati.
  String? get myActiveSosDocumentId => _myActiveSosDocumentId;
  String? _myActiveSosDocumentId;

  /// Agar o‘rnatilsa, SMS fallback'da shu funksiya chaqiriladi.
  /// Ilova boot paytida `url_launcher` bilan to‘ldirishga tavsiya etiladi:
  /// ```dart
  /// sosService.smsHandler = (uri) async {
  ///   if (await canLaunchUrl(uri)) await launchUrl(uri);
  /// };
  /// ```
  SosSmsHandler? smsHandler;

  Stream<List<EmergencySignal>> get emergencySignals {
    final fs = _firestore;
    if (fs == null) return Stream.value([]);
    return fs
        .collection('emergency_signals')
        .where('isActive', isEqualTo: true)
        .where('timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(hours: 4)))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencySignal.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// SOS signalini yuboradi. Onlayn bo‘lsa to‘g‘ridan to‘g‘ri, aks holda
  /// offline queue'ga qo‘shadi. [smsFallback] true bo‘lsa SMS ham yuboradi.
  Future<void> sendSos(
    LatLng position,
    String name, {
    bool smsFallback = false,
    String? emergencyNumber,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user == null) return;

    lastSendQueued = false;
    _myActiveSosDocumentId = null;

    try {
      final fs = _firestore;
      if (fs == null) throw StateError('no-firestore');
      final ref = await fs.collection('emergency_signals').add({
        'senderUid': user.uid,
        'senderName': name,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      _myActiveSosDocumentId = ref.id;
      notifyListeners();
    } catch (e) {
      debugPrint('SOS direct-send failed, queuing: $e');
      await SosQueue.enqueue(
        senderUid: user.uid,
        senderName: name,
        lat: position.latitude,
        lng: position.longitude,
      );
      lastSendQueued = true;
      notifyListeners();
    }

    if (smsFallback && emergencyNumber != null && emergencyNumber.isNotEmpty) {
      await _trySendSms(
        number: emergencyNumber,
        name: name,
        position: position,
      );
    }
  }

  /// Ilovada saqlanmagan bo‘lsa ham, foydalanuvchining oxirgi faol SOS
  /// hujjatini topadi (qayta kirganda `myActiveSosDocumentId` tiklash uchun).
  Future<String?> _latestActiveSosIdForCurrentUser() async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    final fs = _firestore;
    if (fs == null) return null;
    try {
      final snap = await fs
          .collection('emergency_signals')
          .where('senderUid', isEqualTo: user.uid)
          .limit(25)
          .get();
      DateTime? bestTime;
      String? bestId;
      for (final d in snap.docs) {
        final m = d.data();
        if (m['isActive'] != true) continue;
        final t = (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
        if (bestId == null || t.isAfter(bestTime ?? DateTime(1970))) {
          bestTime = t;
          bestId = d.id;
        }
      }
      return bestId;
    } catch (e) {
      debugPrint('SOS: active id lookup failed: $e');
      return null;
    }
  }

  /// Kirish yoki fonda qaytishda chaqiriladi — `myActiveSosDocumentId`ni
  /// server bilan sinxronlaydi.
  Future<void> syncActiveSosFromServer() async {
    final id = await _latestActiveSosIdForCurrentUser();
    if (_myActiveSosDocumentId == id) {
      return;
    }
    _myActiveSosDocumentId = id;
    lastSendQueued = false;
    notifyListeners();
  }

  /// Yuborilgan faol SOS ni serverda o‘chirish (karta/royxatda yo‘qoladi).
  /// Ilovadagi hujjat identifikatori saqlanmagan bo‘lsa, avval qidiradi.
  /// [false] qaytadi, agar server yangilanishi bajarilmasa.
  Future<bool> cancelMyActiveSos() async {
    _myActiveSosDocumentId ??= await _latestActiveSosIdForCurrentUser();
    final id = _myActiveSosDocumentId;
    if (id == null) {
      return false;
    }
    final ok = await _deactivateSosOnServer(id);
    if (ok) {
      if (_myActiveSosDocumentId == id) {
        _myActiveSosDocumentId = null;
        notifyListeners();
      }
    }
    return ok;
  }

  Future<void> _trySendSms({
    required String number,
    required String name,
    required LatLng position,
  }) async {
    final handler = smsHandler;
    if (handler == null) return;
    final body = Uri.encodeComponent(
      'SOS: $name. Location: ${position.latitude}, ${position.longitude}. '
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
    );
    final uri = Uri.parse('sms:$number?body=$body');
    try {
      await handler(uri);
    } catch (e) {
      debugPrint('SMS fallback failed: $e');
    }
  }

  /// Faqat server `isActive: false` qilgandagina mahalliy holat tozalanadi.
  Future<bool> _deactivateSosOnServer(String signalId) async {
    final fs = _firestore;
    if (fs == null) return false;
    try {
      await fs
          .collection('emergency_signals')
          .doc(signalId)
          .update({'isActive': false});
      return true;
    } catch (e) {
      debugPrint('Error clearing SOS: $e');
      return false;
    }
  }

  /// Queue'dagi pending signallar sonini olish.
  Future<int> pendingCount() => SosQueue.pendingCount();

  /// Tarmoqqa chiqmagan (offline) SOS navbatini tozalash.
  Future<void> clearQueuedSignals() async {
    await SosQueue.clearAll();
    lastSendQueued = false;
    notifyListeners();
  }

  /// Auto-flush'ni boshlash (app init'da bir marta chaqiriladi).
  Future<void> startAutoFlush() => SosQueue.startAutoFlush();
}
