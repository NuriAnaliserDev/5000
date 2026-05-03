import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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

  /// Ehtiyoj tugaguncha oqimni ushlab turish.
  void acquire() {
    _refCount++;
    if (_refCount == 1) {
      _start();
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

  void _start() {
    if (_geolocatorSubscription != null) {
      return;
    }
    if (kIsWeb) {
      _attachStream(
        const LocationSettings(
            accuracy: LocationAccuracy.best, distanceFilter: 0),
      );
      return;
    }
    final t = defaultTargetPlatform;
    if (t == TargetPlatform.android) {
      _attachStream(
        AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
          intervalDuration: const Duration(seconds: 3),
          forceLocationManager: false,
          useMSLAltitude: true,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "GeoField Pro N GPS ishlamoqda...",
            notificationTitle: "GPS Faol",
            enableWakeLock: false,
          ),
        ),
      );
      return;
    }
    if (t == TargetPlatform.iOS || t == TargetPlatform.macOS) {
      _attachStream(
        AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.other,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        ),
      );
      return;
    }
    _attachStream(
      const LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: 0),
    );
  }

  void _attachStream(LocationSettings locationSettings) {
    _geolocatorSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (p) {
        if (!_controller.isClosed) {
          _controller.add(p);
        }
      },
      onError: (e) {
        if (kDebugMode) {
          debugPrint('GpsBroadcaster: $e');
        }
      },
    );
  }

  void _stop() {
    _geolocatorSubscription?.cancel();
    _geolocatorSubscription = null;
  }
}
