import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../config/cloud_features.dart';
import '../models/station.dart';
import '../models/track_data.dart';
import '../models/chat_message.dart';
import '../utils/firebase_ready.dart';
import 'hive_db.dart';

class CloudSyncService extends ChangeNotifier {
  FirebaseFirestore? get _firestore => firestoreOrNull;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Hozirgi foydalanuvchining UID'ini qaytaradi.
  /// Agar login bo'lmagan bo'lsa — null. Operatsiyalar faqat auth bo'lganda ishlaydi.
  String? get _currentUserId {
    if (!isFirebaseCoreReady) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // Initialize background connectivity listener
  void init() {
    if (_firestore == null) {
      debugPrint('CloudSyncService: Firebase yo‘q — sinxron o‘chiq.');
      return;
    }
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          debugPrint(
              'Haqiqiy internet aniqlandi: Sinxronizatsiya boshlandi...');
          await _processSyncQueue();
        }
      }
    });

    // Check on startup immediately
    Connectivity().checkConnectivity().then((results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          await _processSyncQueue();
        }
      }
    });

    // Auto-sync har 3 daqiqada batareyani tejash uchun
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi)) {
        if (await hasRealInternet()) {
          await _processSyncQueue();
        }
      }
    });
  }

  Future<bool> hasRealInternet() async {
    if (kIsWeb) return true;
    try {
      // PERFORMANCE FIX: 3 sekundlik timeout — dala sharoitida DNS hang bo'lib
      // qolishi mumkin. Timeoutsiz bu call UI ni freeze qilishi mumkin edi.
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3), onTimeout: () => []);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // Jami tarmoqqa yozilmagan (unsynced) ma'lumotlarni yuborish
  Future<void> _processSyncQueue() async {
    final fs = _firestore;
    if (fs == null) return;
    // Auth bo'lmagan holda sinxronlash xavfli
    if (_currentUserId == null) {
      debugPrint(
          'SyncQueue: foydalanuvchi autentifikatsiya qilinmagan, o\'tkazib yuborildi.');
      return;
    }

    if (_isSyncing) return;

    try {
      _isSyncing = true;
      notifyListeners();
      final syncBox = Hive.box(HiveDb.syncStateBox);
      final stationsBox = Hive.box<Station>(HiveDb.stationsBox);
      final tracksBox = Hive.box<TrackData>(HiveDb.tracksBox);

      // Station Queue
      for (final key in stationsBox.keys) {
        if (syncBox.get('station_$key') != true) {
          final s = stationsBox.get(key);
          if (s != null) {
            final bool success = await _syncStationDirectly(key, s);
            if (success) syncBox.put('station_$key', true);
          }
        }
      }

      // Track Queue (Shift Logs)
      for (final key in tracksBox.keys) {
        final t = tracksBox.get(key);
        if (t != null && !t.isSynced && t.endTime != null) {
          final bool success = await _syncShiftLog(key, t);
          if (success) syncBox.put('track_$key', true);
        }
      }

      // Chat Queue (Pending Messages)
      final chatBox = Hive.box<ChatMessage>(HiveDb.chatMessagesBox);
      final pendingChats =
          chatBox.values.where((m) => m.status == 'pending').toList();
      for (var msg in pendingChats) {
        await _syncPendingChatDirectly(msg);
      }
    } catch (e) {
      debugPrint('SyncQueue error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Tizim ichki foydalanishi uchun
  Future<bool> _syncStationDirectly(dynamic key, Station station) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    final fs = _firestore;
    if (fs == null) return false;

    try {
      // Stansiyalar foydalanuvchi UID ostida saqlanadi — boshqa foydalanuvchilar ko'ra olmaydi
      final docRef = fs
          .collection('users')
          .doc(uid)
          .collection('stations')
          .doc(key.toString());

      String? remotePhotoUrl;
      String? remoteAudioUrl;
      List<String> remotePhotoUrls = [];

      if (kFirebaseStorageUploadsEnabled && isFirebaseCoreReady) {
        final storage = FirebaseStorage.instance;
        // Upload single legacy photo if exists
        if (station.photoPath != null &&
            !kIsWeb &&
            File(station.photoPath!).existsSync()) {
          final ref =
              storage.ref().child('users/$uid/stations/$key/main_photo.jpg');
          await ref.putFile(File(station.photoPath!));
          remotePhotoUrl = await ref.getDownloadURL();
        }

        // Upload multi-photos
        if (station.photoPaths != null) {
          for (int i = 0; i < station.photoPaths!.length; i++) {
            final path = station.photoPaths![i];
            if (!kIsWeb && File(path).existsSync()) {
              final ref =
                  storage.ref().child('users/$uid/stations/$key/photo_$i.jpg');
              await ref.putFile(File(path));
              final url = await ref.getDownloadURL();
              remotePhotoUrls.add(url);
            }
          }
        }

        // Upload audio
        if (station.audioPath != null &&
            !kIsWeb &&
            File(station.audioPath!).existsSync()) {
          final ref =
              storage.ref().child('users/$uid/stations/$key/audio_note.m4a');
          await ref.putFile(File(station.audioPath!));
          remoteAudioUrl = await ref.getDownloadURL();
        }
      }

      final data = {
        'uid': uid,
        'name': station.name,
        'lat': station.lat,
        'lng': station.lng,
        'altitude': station.altitude,
        'strike': station.strike,
        'dip': station.dip,
        'azimuth': station.azimuth,
        'date': station.date.toIso8601String(),
        'rockType': station.rockType,
        'structure': station.structure,
        'color': station.color,
        'description': station.description,
        'accuracy': station.accuracy,
        'project': station.project,
        'measurementType': station.measurementType,
        'dipDirection': station.dipDirection,
        'sampleId': station.sampleId,
        'sampleType': station.sampleType,
        'confidence': station.confidence,
        'munsellColor': station.munsellColor,
        'photoUrl': remotePhotoUrl,
        'photoUrls': remotePhotoUrls,
        'audioUrl': remoteAudioUrl,
        'hasPhoto': remotePhotoUrl != null || remotePhotoUrls.isNotEmpty,
        'hasAudio': remoteAudioUrl != null,
        'authorName': station.authorName,
        'authorRole': station.authorRole,
        'syncedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Failed to sync station $key: $e');
      return false;
    }
  }

  Future<bool> _syncShiftLog(dynamic key, TrackData track) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    final fs = _firestore;
    if (fs == null) return false;

    try {
      final docRef = fs
          .collection('users')
          .doc(uid)
          .collection('shift_logs')
          .doc(key.toString());
      final data = {
        'uid': uid,
        'name': track.name,
        'authorName': track.authorName ?? 'Noma\'lum',
        'authorRole': track.authorRole ?? 'User',
        'shiftLabel': track.shiftLabel ?? '1-smena',
        'startTime': track.startTime.toIso8601String(),
        'endTime': track.endTime?.toIso8601String(),
        'distanceMeters': track.distanceMeters,
        'points': track.points.map((p) => p.toJson()).toList(),
        'syncedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));

      // Update local state to mark as synced
      track.isSynced = true;
      await track.save();

      return true;
    } catch (e) {
      debugPrint('Failed to sync shift log $key: $e');
      return false;
    }
  }

  Future<void> _syncPendingChatDirectly(ChatMessage msg) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final fs = _firestore;
    if (fs == null) return;

    try {
      String? remoteMediaUrl;

      if (kFirebaseStorageUploadsEnabled &&
          isFirebaseCoreReady &&
          msg.mediaPath != null &&
          !kIsWeb &&
          File(msg.mediaPath!).existsSync()) {
        final file = File(msg.mediaPath!);
        final ref = FirebaseStorage.instance
            .ref()
            .child('chats/${msg.groupId}/${msg.id}');
        await ref.putFile(file);
        remoteMediaUrl = await ref.getDownloadURL();
      }

      await fs
          .collection('chat_groups')
          .doc(msg.groupId)
          .collection('messages')
          .doc(msg.id)
          .set({
        'id': msg.id,
        'groupId': msg.groupId,
        'senderId': uid,
        'senderName': msg.senderName,
        'text': msg.text,
        'timestamp': msg.timestamp.toIso8601String(),
        'messageType': msg.messageType,
        'mediaUrl': remoteMediaUrl,
        'lat': msg.lat,
        'lng': msg.lng,
        if (msg.editedAt != null) 'editedAt': msg.editedAt!.toIso8601String(),
      });

      msg.status = 'sent';
      await msg.save();
    } catch (e) {
      debugPrint('Failed to sync chat message ${msg.id}: $e');
      // Failure keeps msg.status = 'pending'. Next queue run will retry.
    }
  }

  // Qo'lda (yoki stansiya qo'shilganida) chaqirish uchun ochiq API
  Future<void> syncStation(int key, Station station) async {
    final bool ok = await _syncStationDirectly(key, station);
    if (ok) {
      Hive.box(HiveDb.syncStateBox).put('station_$key', true);
    }
  }

  /// Sinxronizatsiyani majburan ishga tushiradi.
  /// `await` bilan to'g'ri ishlatiladi — xatolar tashqariga chiqadi.
  Future<void> triggerSync() async {
    await _processSyncQueue();
  }

  /// Faqat JORIY foydalanuvchining stansiyasini o'chiradi (UID-scoped).
  Future<void> deleteStation(int key) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final fs = _firestore;
    if (fs == null) return;

    try {
      await fs
          .collection('users')
          .doc(uid)
          .collection('stations')
          .doc(key.toString())
          .delete();
      Hive.box(HiveDb.syncStateBox).delete('station_$key');
    } catch (e) {
      debugPrint('Cloud delete fail: $e');
    }
  }

  /// XAVFLI OPERATSIYA — faqat foydalanuvchining o'z stansiyalarini o'chiradi.
  /// Batch delete ishlatiladi — interrupt xavfini kamaytirish uchun.
  Future<void> clearUserStations() async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint(
          'clearUserStations: foydalanuvchi login qilmagan, operatsiya bekor qilindi.');
      return;
    }

    try {
      final fs = _firestore;
      if (fs == null) return;
      final batch = fs.batch();
      final snapshot =
          await fs.collection('users').doc(uid).collection('stations').get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      Hive.box(HiveDb.syncStateBox).clear();
      debugPrint(
          'clearUserStations: ${snapshot.docs.length} stansiya o\'chirildi (uid: $uid).');
    } catch (e) {
      debugPrint('clearUserStations fail: $e');
    }
  }

  /// Smart Purge — Eski sinxronlangan ma'lumotlarni LOCAL'dan o'chiradi.
  /// FAQAT cloud'da muvaffaqiyatli saqlanganlari o'chiriladi.
  /// [thresholdDays] — necha kundan eski ma'lumotlar tozalansin.
  /// [dryRun] = true bo'lsa, faqat hisob chiqaradi, o'chirmaydi.
  Future<int> runSmartPurge(int thresholdDays, {bool dryRun = false}) async {
    if (_isSyncing) return 0;

    final stationsBox = Hive.box<Station>(HiveDb.stationsBox);
    final tracksBox = Hive.box<TrackData>(HiveDb.tracksBox);
    final syncBox = Hive.box(HiveDb.syncStateBox);

    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: thresholdDays));

    int purgedCount = 0;

    // Purge Stations — faqat cloud'da tasdiqlanganlari
    for (var key in stationsBox.keys.toList()) {
      final s = stationsBox.get(key);
      if (s != null && syncBox.get('station_$key') == true) {
        if (s.date.isBefore(threshold)) {
          if (!dryRun) {
            await stationsBox.delete(key);
            await syncBox.delete('station_$key');
          }
          purgedCount++;
        }
      }
    }

    // Purge Tracks (Shift Logs)
    for (var key in tracksBox.keys.toList()) {
      final t = tracksBox.get(key);
      if (t != null && t.isSynced && t.endTime != null) {
        if (t.endTime!.isBefore(threshold)) {
          if (!dryRun) {
            await tracksBox.delete(key);
            await syncBox.delete('track_$key');
          }
          purgedCount++;
        }
      }
    }

    final action = dryRun ? '[DRY RUN]' : '';
    if (purgedCount > 0) {
      debugPrint(
        'SmartPurge$action: $purgedCount yozuv $thresholdDays-kunlik chegaradan o\'tgan.',
      );
    }
    return purgedCount;
  }
}
