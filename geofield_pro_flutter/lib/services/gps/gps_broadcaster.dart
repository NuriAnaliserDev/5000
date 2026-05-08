import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/diagnostics/app_timeouts.dart';
import '../../core/diagnostics/production_diagnostics.dart';

/// Bitta `Geolocator.getPositionStream` — barcha iste'molchilar
/// ([LocationService], [TrackService] va h.k.) shu oqimdan foydalanadi.
///
/// Boshqaruv: [acquire] / [release] — referens hisob. 0 bo'lsa Geolocator
/// obyektiga obuna bekor qilinadi (batareya).
class GpsBroadcaster {
  GpsBroadcaster._();
  static final GpsBroadcaster instance = GpsBroadcaster._();

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast(sync: true);

  /// Barcha GPS yangilanishlari.
  Stream<Position> get positionStream => _controller.stream;

  StreamSubscription<Position>? _geolocatorSubscription;
  int _refCount = 0;
  Timer? _errorRecoverTimer;

  /// Ehtiyoj tugaguncha oqimni ushlab turish.
  void acquire() {
    _refCount++;
    if (_refCount == 1) {
      _ensureStreamSubscribed();
    }
  }

  /// [acquire] jufti — oxirgisi bo'lsa Geolocator to'xtatiladi.
  void release() {
    if (_refCount <= 0) {
      return;
    }
    _refCount--;
    if (_refCount == 0) {
      _stop();
    }
  }

  int get referenceCount => _refCount;

  void _ensureStreamSubscribed() {
    if (_geolocatorSubscription != null) {
      return;
    }
    _subscribeWithSettings(_platformSettings());
  }

  LocationSettings _platformSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }
    final t = defaultTargetPlatform;
    if (t == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        intervalDuration: const Duration(seconds: 3),
        forceLocationManager: false,
        useMSLAltitude: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'GeoField Pro N GPS ishlamoqda...',
          notificationTitle: 'GPS Faol',
          enableWakeLock: false,
        ),
      );
    }
    if (t == TargetPlatform.iOS || t == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  void _recoverFromStreamError() {
    if (_refCount <= 0) {
      return;
    }
    _geolocatorSubscription?.cancel();
    _geolocatorSubscription = null;
    _subscribeWithSettings(_platformSettings());
  }

  void _scheduleStreamRecover(Object error) {
    if (_refCount <= 0) {
      return;
    }
    _errorRecoverTimer?.cancel();
    _errorRecoverTimer = Timer(AppTimeouts.gpsStreamRecoverDelay, () {
      _errorRecoverTimer = null;
      if (_refCount <= 0) {
        return;
      }
      try {
        _recoverFromStreamError();
      } catch (e, st) {
        unawaited(
          ProductionDiagnostics.gps(
            'broadcaster_recover_failed',
            data: {
              'first': error.toString(),
              'recover': e.toString(),
              if (kDebugMode) 'stack': st.toString(),
            },
          ),
        );
      }
    });
  }

  void _subscribeWithSettings(LocationSettings locationSettings) {
    _geolocatorSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (p) {
        if (!_controller.isClosed) {
          _controller.add(p);
        }
      },
      onError: (Object e, StackTrace st) {
        unawaited(
          ProductionDiagnostics.gps(
            'broadcaster_stream_error',
            data: {'error': e.toString()},
          ),
        );
        if (kDebugMode) {
          debugPrint('GpsBroadcaster: $e');
        }
        _scheduleStreamRecover(e);
      },
      cancelOnError: false,
    );
  }

  void _stop() {
    _errorRecoverTimer?.cancel();
    _errorRecoverTimer = null;
    _geolocatorSubscription?.cancel();
    _geolocatorSubscription = null;
  }
}
