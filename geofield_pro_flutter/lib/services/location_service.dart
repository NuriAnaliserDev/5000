import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

import '../core/diagnostics/app_timeouts.dart';
import '../core/diagnostics/production_diagnostics.dart';

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
  bool _loggedFirstGpsFix = false;
  bool _refreshInFlight = false;

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
          unawaited(refreshLocation());
        }
      }
    });
  }

  Future<void> _init() async {
    unawaited(
      ProductionDiagnostics.gps('init_begin'),
    );
    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(AppTimeouts.locationServiceProbe);
    } catch (e) {
      _isServiceEnabled = false;
      unawaited(
        ProductionDiagnostics.gps(
          'service_enabled_probe_timeout',
          data: {'error': e.toString()},
        ),
      );
    }
    if (!_isServiceEnabled) {
      _status = GpsStatus.off;
      notifyListeners();
      unawaited(
        ProductionDiagnostics.gps(
          'init_complete',
          phase: 'service_off',
          data: {'status': _status.name},
        ),
      );
      return;
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission()
          .timeout(AppTimeouts.gpsPermissionProbe);
    } catch (e) {
      permission = LocationPermission.denied;
      unawaited(
        ProductionDiagnostics.gps(
          'check_permission_timeout',
          data: {'error': e.toString()},
        ),
      );
    }
    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission()
            .timeout(AppTimeouts.gpsPermissionProbe);
      } catch (e) {
        permission = LocationPermission.denied;
        unawaited(
          ProductionDiagnostics.gps(
            'request_permission_timeout',
            data: {'error': e.toString()},
          ),
        );
      }
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = GpsStatus.denied;
      notifyListeners();
      unawaited(
        ProductionDiagnostics.gps(
          'init_complete',
          phase: 'permission_denied',
          data: {'status': _status.name, 'permission': permission.name},
        ),
      );
      return;
    }

    _status = GpsStatus.searching;
    notifyListeners();

    // Initial positioning
    refreshLocation();

    _serviceStatusSub ??=
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final wasEnabled = _isServiceEnabled;
      _isServiceEnabled = (status == ServiceStatus.enabled);
      if (!_isServiceEnabled) {
        _status = GpsStatus.off;
        _currentPosition = null;
      } else {
        _status = GpsStatus.searching;
        refreshLocation();
      }
      notifyListeners();
      unawaited(
        ProductionDiagnostics.gps(
          'service_status',
          data: {
            'enabled': _isServiceEnabled,
            'was_enabled': wasEnabled,
          },
        ),
      );
    });

    _attachGpsStream();
    unawaited(
      ProductionDiagnostics.gps(
        'init_complete',
        phase: 'stream_attached',
        data: {'status': _status.name, 'permission': permission.name},
      ),
    );
  }

  void _onGpsPosition(Position position) {
    try {
      final age = DateTime.now().difference(position.timestamp);
      if (age > AppTimeouts.gpsFixMaxAge) {
        unawaited(
          ProductionDiagnostics.gps(
            'stale_fix_ignored',
            data: {'age_sec': age.inSeconds},
          ),
        );
        unawaited(refreshLocation());
        return;
      }
    } catch (_) {}

    _currentPosition = position;
    _lastUpdateTime = DateTime.now();
    _updateStatus(position.accuracy);
    _logGpsTrustFlags(position, 'stream');
    if (!_loggedFirstGpsFix) {
      _loggedFirstGpsFix = true;
      unawaited(
        ProductionDiagnostics.gps(
          'first_position',
          data: {
            'accuracy_m': position.accuracy,
            'lat_round': (position.latitude * 1000).round() / 1000,
            'lng_round': (position.longitude * 1000).round() / 1000,
          },
        ),
      );
    }
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
      onError: (Object e, StackTrace st) {
        _status = GpsStatus.off;
        notifyListeners();
        unawaited(
          ProductionDiagnostics.gps(
            'stream_error',
            data: {'error': e.toString()},
          ),
        );
      },
    );
  }

  void _updateStatus(double accuracy) {
    if (accuracy < 5) {
      _status = GpsStatus.good; // <5m — Geologik ish uchun ideal
    } else if (accuracy < 15) {
      _status = GpsStatus.medium; // 5–15m — Qabul qilinarli
    } else {
      _status = GpsStatus.poor; // >15m — Aniqlik past
    }
  }

  /// Mock GPS / eskirgan sensor (fix vaqti) — diagnostika; saqlashdan mustaqil.
  void _logGpsTrustFlags(Position position, String phase) {
    var mock = false;
    try {
      mock = position.isMocked;
    } catch (_) {}
    final age = DateTime.now().difference(position.timestamp);
    final stale = age > AppTimeouts.gpsFixMaxAge;
    final acc = position.accuracy;
    final badAcc = !acc.isFinite || acc < 0 || acc > 50000;
    if (!mock && !stale && !badAcc) {
      return;
    }
    unawaited(
      ProductionDiagnostics.gps(
        'trust_alert',
        phase: phase,
        data: {
          'mock': mock,
          'stale': stale,
          'bad_acc': badAcc,
          'age_sec': age.inSeconds,
          'accuracy_m': position.accuracy,
        },
      ),
    );
  }

  /// Ilova fon/oldinga o‘tganda: ruxsat, servis holati, Geolocator oqimi qayta ulanadi.
  Future<void> onApplicationResumed() async {
    unawaited(ProductionDiagnostics.gps('app_resumed_location_recheck'));
    try {
      try {
        _isServiceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(AppTimeouts.locationServiceProbe);
      } catch (e) {
        _isServiceEnabled = false;
        unawaited(
          ProductionDiagnostics.gps(
            'resume_service_probe_failed',
            data: {'error': e.toString()},
          ),
        );
      }

      if (!_isServiceEnabled) {
        await _positionSubscription?.cancel();
        _positionSubscription = null;
        if (_gpsAcquired) {
          GpsBroadcaster.instance.release();
          _gpsAcquired = false;
        }
        _status = GpsStatus.off;
        _currentPosition = null;
        notifyListeners();
        return;
      }

      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission()
            .timeout(AppTimeouts.gpsPermissionProbe);
      } catch (e) {
        permission = LocationPermission.denied;
        unawaited(
          ProductionDiagnostics.gps(
            'resume_check_permission_timeout',
            data: {'error': e.toString()},
          ),
        );
      }
      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission()
              .timeout(AppTimeouts.gpsPermissionProbe);
        } catch (e) {
          permission = LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _positionSubscription?.cancel();
        _positionSubscription = null;
        if (_gpsAcquired) {
          GpsBroadcaster.instance.release();
          _gpsAcquired = false;
        }
        _status = GpsStatus.denied;
        _currentPosition = null;
        notifyListeners();
        unawaited(
          ProductionDiagnostics.gps(
            'resume_permission_blocked',
            data: {'permission': permission.name},
          ),
        );
        return;
      }

      if (_status == GpsStatus.denied || _status == GpsStatus.off) {
        _status = GpsStatus.searching;
      }
      _attachGpsStream();
      await refreshLocation();
      notifyListeners();
    } catch (e) {
      debugPrint('onApplicationResumed location: $e');
      unawaited(
        ProductionDiagnostics.gps(
          'resume_location_failed',
          data: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> restartService() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _staleCheckTimer?.cancel();
    _staleCheckTimer = null;
    if (_gpsAcquired) {
      GpsBroadcaster.instance.release();
      _gpsAcquired = false;
    }
    _status = GpsStatus.searching;
    notifyListeners();
    await _init();
    _startStaleCheck();
    debugPrint("GPS Service Restarted - Forcing fresh data");
  }

  Future<void> refreshLocation() async {
    if (_refreshInFlight) {
      return;
    }
    _refreshInFlight = true;
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
      ).timeout(AppTimeouts.getCurrentPositionOuter);
      _currentPosition = position;
      _lastUpdateTime = DateTime.now();
      _updateStatus(position.accuracy);
      _logGpsTrustFlags(position, 'refresh');
      notifyListeners();
    } catch (e) {
      debugPrint("Refresh failed: $e");
      unawaited(
        ProductionDiagnostics.gps(
          'refresh_failed',
          data: {'error': e.toString()},
        ),
      );
    } finally {
      _refreshInFlight = false;
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
