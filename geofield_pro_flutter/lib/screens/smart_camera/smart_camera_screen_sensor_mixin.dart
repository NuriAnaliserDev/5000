part of 'smart_camera_screen.dart';

/// Sensorlar (kompass, akselerometr, magnetometr) va geologik orientatsiya HIS-kit —
/// [SmartCameraScreenState] dan ajratilgan.
mixin SmartCameraSensorMixin on SmartCameraStateFields {
  void _startSensors() {
    _stopSensors();
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      final acc = event.accuracy;
      if (acc != null) {
        final bool isGoodNow = acc > 0 && acc < 15;
        final bool wasBadBefore = _lastAccuracy == null ||
            _lastAccuracy! <= 0 ||
            _lastAccuracy! >= 15;
        if (isGoodNow &&
            wasBadBefore &&
            _showCalibrationHint &&
            !_miniCalibrationDismissed) {
          HapticFeedback.mediumImpact();
        }
        _lastAccuracy = acc;

        final double q = 1.0 - (acc / 45.0);
        _compassQuality = (q.clamp(0.0, 1.0) * 100).toInt();
      }
      if (h != null && !h.isNaN) {
        final target = h % 360;
        if (_headingDeg == null) {
          _headingDeg = target;
        } else {
          var diff = target - _headingDeg!;
          if (diff > 180) {
            diff -= 360;
          }
          if (diff < -180) {
            diff += 360;
          }
          _headingDeg = (_headingDeg! + diff * _headingSmooth) % 360;
        }
      }
    });
    _accelSub = accelerometerEventStream().listen((event) {
      _gravity = Vec3(event.x, event.y, event.z);
      _recomputeOrientation();
    });
    _magSub = magnetometerEventStream().listen((event) {
      _mag = event;
      _recomputeOrientation();
    });
  }

  void _stopSensors() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _compassSub?.cancel();
    _accelSub = null;
    _magSub = null;
    _compassSub = null;
  }

  void _recomputeOrientation() {
    if (!mounted) {
      return;
    }
    final settings = _settings;
    final locService = _locationService;
    if (settings == null || locService == null) {
      return;
    }
    final mag = _mag;
    final g = _gravity;
    if (mag == null || g == null) {
      return;
    }
    final now = DateTime.now();
    final delay = settings.ecoMode
        ? (_highSensitivityHorizon ? 80 : 120)
        : (_highSensitivityHorizon ? 30 : 50);
    if (now.difference(_lastSensorUpdate).inMilliseconds < delay) {
      return;
    }
    _lastSensorUpdate = now;

    final pos = locService.currentPosition;
    final result = calculateGeologicalOrientation(
      gravity: g,
      magnetic: Vec3(mag.x, mag.y, mag.z),
      lat: pos?.latitude ?? 0,
      lng: pos?.longitude ?? 0,
      manualDeclination: settings.magneticDeclination,
    );
    var targetAz = result.azimuth;
    if (_headingDeg != null) {
      var hd = _headingDeg! - targetAz;
      if (hd > 180) {
        hd -= 360;
      }
      if (hd < -180) {
        hd += 360;
      }
      if (hd.abs() < 35) {
        targetAz = (targetAz + hd * 0.20) % 360;
      }
    }
    var azDiff = targetAz - _azimuth;
    if (azDiff > 180) {
      azDiff -= 360;
    }
    if (azDiff < -180) {
      azDiff += 360;
    }
    _azimuth = ((_azimuth + azDiff * _azimuthSmooth) % 360 + 360) % 360;

    _dip = (_dip * (1 - _dipStrikeSmooth) + result.dip * _dipStrikeSmooth);

    var stDiff = result.strike - _strike;
    if (stDiff > 180) {
      stDiff -= 360;
    }
    if (stDiff < -180) {
      stDiff += 360;
    }
    _strike = ((_strike + stDiff * _dipStrikeSmooth) % 360 + 360) % 360;

    _pitch = (_pitch * (1 - _horizonSmooth) + result.pitch * _horizonSmooth);
    _roll = (_roll * (1 - _horizonSmooth) + result.roll * _horizonSmooth);

    final bool isLeveled = _pitch.abs() < 1.5 && _roll.abs() < 1.5;
    if (isLeveled && !_wasLeveled) {
      HapticFeedback.lightImpact();
    }
    _wasLeveled = isLeveled;

    _lastHudPitch = _pitch;
    _lastHudRoll = _roll;
    _lastHudStrike = _strike;
    _lastHudDip = _dip;

    if (mounted && now.difference(_lastUiUpdate).inMilliseconds >= 80) {
      _lastUiUpdate = now;
      setState(() {});
    }
  }
}
