import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/track_data.dart';
import 'hive_db.dart';
import 'cloud_sync_service.dart';
import 'gps/gps_broadcaster.dart';

class TrackService extends ChangeNotifier {
  final CloudSyncService _cloudSyncService;

  StreamSubscription<Position>? _positionStream;
  TrackData? currentTrack;

  Timer? _sessionTimer;
  Timer? _baseDwellTimer;
  Timer? _notificationDebounceTimer;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool get isTracking => currentTrack != null && _positionStream != null;

  List<TrackData> get storedTracks =>
      Hive.box<TrackData>('tracks').values.toList().reversed.toList();

  TrackService(this._cloudSyncService) {
    _initNotifications();
    checkAndPurgeOldTracks();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    // Request permission for Android 13+
    _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void checkAndPurgeOldTracks() {
    final box = Hive.box<TrackData>('tracks');
    final settingsBox = Hive.box(HiveDb.settingsBox);
    final purgeDays = settingsBox.get('autoPurgeDays', defaultValue: 30) as int;

    final now = DateTime.now();
    final keysToDelete = <dynamic>[];
    int totalPoints = 0;

    for (final key in box.keys) {
      final track = box.get(key);
      if (track != null) {
        // Zaryad tugashi yoki Crash holatini tiklash:
        if (track.endTime == null) {
          final lastActiveTime = track.points.isNotEmpty
              ? track.points.last.time
              : track.startTime;
          if (now.difference(lastActiveTime).inHours > 12) {
            track.endTime = lastActiveTime;
            track.save();
          }
        }

        if (now.difference(track.startTime).inDays >= purgeDays) {
          keysToDelete.add(key);
        } else {
          totalPoints += track.points.length;
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      box.deleteAll(keysToDelete);
    }

    if (totalPoints > 200000) {
      _showWarningNotification('Arxiv xajmi kattalashdi',
          'Tizim xotirasini bo\'shatish uchun keraksiz marshrutlarni o\'chiring');
    }
  }

  Future<void> _showWarningNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
        'geofield_alerts', 'GeoField Orqa Fon',
        importance: Importance.high, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(0, title, body, details);
  }

  Future<void> startTracking(String name) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final settingsBox = Hive.box(HiveDb.settingsBox);
    final authorName = settingsBox.get('currentUserName') as String?;
    final expert = settingsBox.get('expertMode', defaultValue: false) as bool;
    final authorRole = expert ? 'Professional' : null;

    final newTrack = TrackData(
      name: name,
      startTime: DateTime.now(),
      points: [],
      distanceMeters: 0.0,
      authorName: authorName,
      authorRole: authorRole,
      shiftLabel: '1-smena', // Standard shift
    );
    currentTrack = newTrack;

    await Hive.box<TrackData>('tracks').add(newTrack);

    notifyListeners();

    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(hours: 12), () {
      stopTracking();
      _showWarningNotification(
          'Marshrut Yakunlandi', '12 soatlik ish vaqti tugadi.');
    });

    _startGpsListener();
  }

  void _startGpsListener() {
    _positionStream?.cancel();
    GpsBroadcaster.instance.acquire();
    _positionStream =
        GpsBroadcaster.instance.positionStream.listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position position) {
    final track = currentTrack;
    if (track == null) return;

    // Base dwell logic (kept as is for camp monitoring)
    final settingsBox = Hive.box(HiveDb.settingsBox);
    final baseLat = settingsBox.get('baseLatitude') as double?;
    final baseLng = settingsBox.get('baseLongitude') as double?;

    if (baseLat != null && baseLng != null) {
      final distToBase = Geolocator.distanceBetween(
          position.latitude, position.longitude, baseLat, baseLng);
      if (distToBase < 150.0) {
        _baseDwellTimer ??= Timer(const Duration(hours: 4), () {
          stopTracking();
          _showWarningNotification(
              'Aktivlik to\'xtatildi', 'Bazada 4 soat qoldingiz.');
        });
      } else {
        _baseDwellTimer?.cancel();
        _baseDwellTimer = null;
      }
    }

    if (track.points.isNotEmpty) {
      final last = track.points.last;
      track.distanceMeters += Geolocator.distanceBetween(
        last.lat,
        last.lng,
        position.latitude,
        position.longitude,
      );
    }

    track.points.add(
      TrackPoint(
        lat: position.latitude,
        lng: position.longitude,
        alt: position.altitude,
        time: position.timestamp,
      ),
    );

    // PERFORMANCE FIX: Har 10 nuqtada DISK ga yozish (avval har safar yozilardi).
    // 8 soatlik sessiyada: 9600 → 960 disk I/O operatsiyasi (10x tezlashdi).
    if (track.points.length % 10 == 0) {
      track.save();
    }

    // AUTO-SYNC TRIGGER: Har 50 nuqtada (taxm. 5 min)
    if (track.points.length % 50 == 0) {
      _cloudSyncService.triggerSync();
    }

    // PERFORMANCE FIX: UI rebuild ni har 5 nuqtada bir marta chaqirish.
    // GPS 3 sekundda keladi → har 15 sekundda bir rebuild (avval har 3 sekundda edi).
    if (track.points.length % 5 == 0) {
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    final track = currentTrack;
    if (track == null) return;
    await _positionStream?.cancel();
    _positionStream = null;
    GpsBroadcaster.instance.release();
    _sessionTimer?.cancel();
    _baseDwellTimer?.cancel();
    _notificationDebounceTimer?.cancel();
    _sessionTimer = null;
    _baseDwellTimer = null;
    _notificationDebounceTimer = null;

    track.endTime = DateTime.now();
    track.save();

    // FORCE SYNC on stop
    _cloudSyncService.triggerSync();

    currentTrack = null;
    notifyListeners();
  }

  void recordStationSaved() {
    final track = currentTrack;
    if (track != null) {
      track.stationsCount += 1;
      track.save();
      notifyListeners();
    }
  }

  Future<void> deleteTrack(int key) async {
    final box = Hive.box<TrackData>('tracks');
    await box.delete(key);
    notifyListeners();
  }

  Future<void> renameTrack(int key, String newName) async {
    final box = Hive.box<TrackData>('tracks');
    final track = box.get(key);
    if (track != null) {
      track.name = newName;
      await box.put(key, track);
      notifyListeners();
    }
  }
}
