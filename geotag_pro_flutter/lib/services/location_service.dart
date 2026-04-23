import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

import 'gps/gps_broadcaster.dart';

enum GpsStatus { searching, good, medium, poor, off, denied }

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  GpsStatus _status = GpsStatus.off;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  bool _isServiceEnabled = false;
  Timer? _staleCheckTimer;
  DateTime _lastUpdateTime = DateTime.now();
  bool _gpsAcquired = false;

  Position? get currentPosition => _currentPosition;
  GpsStatus get status => _status;
  double get accuracy => _currentPosition?.accuracy ?? 999;
  double get latitude => _currentPosition?.latitude ?? 0.0;
  double get longitude => _currentPosition?.longitude ?? 0.0;
  DateTime get lastUpdateTime => _lastUpdateTime;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LocationService() {
    // We still trigger it, but UI should check isInitialized
    _init().then((_) {
      _isInitialized = true;
      _startStaleCheck();
      notifyListeners();
    });
  }

  void _startStaleCheck() {
    _staleCheckTimer?.cancel();
    _staleCheckTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_status == GpsStatus.searching || _status == GpsStatus.poor) {
        final now = DateTime.now();
        if (now.difference(_lastUpdateTime).inSeconds > 25) {
          // GPS seems stuck, force a refresh
          refreshLocation();
        }
      }
    });
  }

  Future<void> _init() async {
    _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isServiceEnabled) {
      _status = GpsStatus.off;
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = GpsStatus.denied;
      notifyListeners();
      return;
    }

    _status = GpsStatus.searching;
    notifyListeners();

    // Initial positioning
    refreshLocation();

    _serviceStatusSub ??=
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _isServiceEnabled = (status == ServiceStatus.enabled);
      if (!_isServiceEnabled) {
        _status = GpsStatus.off;
        _currentPosition = null;
      } else {
        _status = GpsStatus.searching;
        refreshLocation();
      }
      notifyListeners();
    });

    _attachGpsStream();
  }

  void _onGpsPosition(Position position) {
    _currentPosition = position;
    _lastUpdateTime = DateTime.now();
    _updateStatus(position.accuracy);
    notifyListeners();
  }

  void _attachGpsStream() {
    _positionSubscription?.cancel();
    if (!_gpsAcquired) {
      GpsBroadcaster.instance.acquire();
      _gpsAcquired = true;
    }
    _positionSubscription = GpsBroadcaster.instance.positionStream.listen(
      _onGpsPosition,
      onError: (_) {
        _status = GpsStatus.off;
        notifyListeners();
      },
    );
  }

  void _updateStatus(double accuracy) {
    if (accuracy < 5) {
      _status = GpsStatus.good;       // <5m — Geologik ish uchun ideal
    } else if (accuracy < 15) {
      _status = GpsStatus.medium;     // 5–15m — Qabul qilinarli
    } else {
      _status = GpsStatus.poor;       // >15m — Aniqlik past
    }
  }

  Future<void> restartService() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _staleCheckTimer?.cancel();
    _staleCheckTimer = null;
    _status = GpsStatus.searching;
    notifyListeners();
    await _init();
    _startStaleCheck();
    debugPrint("GPS Service Restarted - Forcing fresh data");
  }

  Future<void> refreshLocation() async {
    try {
      LocationSettings refreshSettings;
      if (!kIsWeb && Platform.isAndroid) {
        refreshSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
          forceLocationManager: false,
          useMSLAltitude: true,
        );
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        refreshSettings = AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.other,
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        refreshSettings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 8),
        );
      }

      // Force a fresh request bypassing the stream if it's stuck
      final position = await Geolocator.getCurrentPosition(
        locationSettings: refreshSettings,
      );
      _currentPosition = position;
      _lastUpdateTime = DateTime.now();
      _updateStatus(position.accuracy);
      notifyListeners();
    } catch (e) {
      debugPrint("Refresh failed: $e");
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _serviceStatusSub?.cancel();
    if (_gpsAcquired) {
      GpsBroadcaster.instance.release();
      _gpsAcquired = false;
    }
    _staleCheckTimer?.cancel();
    super.dispose();
  }
}
