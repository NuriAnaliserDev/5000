part of 'smart_camera_screen.dart';

class SmartCameraScreenState extends State<SmartCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;

  StreamSubscription<AccelerometerEvent>? _accelSub;

  double _azimuth = 0;
  double _dip = 0;
  double _strike = 0;
  double _pitch = 0;
  double _roll = 0;
  double? _headingDeg;

  double _lastHudPitch = 0;
  double _lastHudRoll = 0;
  double _lastHudStrike = 0;
  double _lastHudDip = 0;

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<CompassEvent>? _compassSub;
  MagnetometerEvent? _mag;
  Vec3? _gravity;
  DateTime _lastSensorUpdate = DateTime.now();
  DateTime _lastUiUpdate = DateTime.now();

  bool _isBusy = false;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  bool _showCalibrationHint = true;
  double _zoom = 1.0;
  FlashMode _flashMode = FlashMode.off;
  bool _showScale = false;
  bool _showHud = true;
  bool _highSensitivityHorizon = false;
  double? _lastAccuracy;
  int _compassQuality = 100;
  bool _wasLeveled = false;
  final bool _miniCalibrationDismissed = false;

  final GlobalKey _sensorLockButtonKey = GlobalKey();
  final GlobalKey _modeToggleKey = GlobalKey();
  final GlobalKey _shutterButtonKey = GlobalKey();
  final GlobalKey _menuButtonKey = GlobalKey();

  GeologicalArSessionController? _arSessionController;

  /// AR oynasi yopilgach (yoki muvaffaqiyatsiz tugagach) kamera ochiladi; qisqa kutish ARCore/ARKit kamera tutqichini bo‘shatishi uchun.
  bool _pendingDelayedCameraInitAfterAr = false;
  Timer? _delayedCameraInitTimer;
  Future<void>? _cameraInitInFlight;

  bool get _geologicalArActive =>
      _cameraMode == CameraMode.geological &&
      (_settings?.geologicalArEnabled ?? false) &&
      geologicalArSupportedPlatform();

  /// [context.read] oqim/pauza oynasida ishlatilmasin — deaktiv elementda Provider xatosi.
  SettingsController? _settings;
  LocationService? _locationService;
  bool _appliedInitialUserPrefs = false;

  CameraMode _cameraMode = CameraMode.geological;

  // ——— Theme (kamera HUD) ———
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => Colors.white;
  Color get subTextColor => Colors.white70;
  List<Shadow> get textShadows => [
        const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
        const Shadow(color: Colors.black, blurRadius: 10),
      ];
  Color get glassColor => Colors.black.withValues(alpha: 0.5);
  Color get glassBorder => Colors.white.withValues(alpha: 0.2);

  // ——— Sensor smoothing ———
  double get _headingSmooth => _highSensitivityHorizon ? 0.52 : 0.38;
  double get _azimuthSmooth => _highSensitivityHorizon ? 0.50 : 0.42;
  double get _dipStrikeSmooth => _highSensitivityHorizon ? 0.34 : 0.30;
  double get _horizonSmooth => _highSensitivityHorizon ? 0.60 : 0.40;

  Future<void> _disableHardwareTorch() async {
    if (kIsWeb) {
      return;
    }
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  // ——— Kamera + sensor ———
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraInitFuture = _cameraController!.initialize();
      await _cameraInitFuture;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _disposeCameraOnly();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.locRead('camera_error')}: $e')),
        );
      }
    }
  }

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

  // ——— Yozib olish + suratga olish ———
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _audioPath = path;
            _recordTimer?.cancel();
            _recordTimer = null;
            _recordSeconds = 0;
          });
        }
        if (mounted && path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.locRead('note_saved')),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(context.locRead('mic_error')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.locRead('confirm')),
                ),
              ],
            ),
          );
        }
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final exportDir =
          Directory('${dir.path}${Platform.pathSeparator}recordings');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final outPath =
          '${exportDir.path}${Platform.pathSeparator}geofield_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: outPath);
      if (mounted) {
        setState(() {
          _isRecording = true;
          _audioPath = null;
          _recordSeconds = 0;
        });
      }
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _recordSeconds++);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locRead('recording_started')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.locRead('record_error')}: $e')),
        );
      }
    }
  }

  Future<void> _capture() async {
    if (_isBusy) {
      return;
    }
    try {
      setState(() => _isBusy = true);
      final settings = context.read<SettingsController>();
      late XFile file;
      if (_geologicalArActive) {
        final path = await _arSessionController?.captureToTempFile();
        if (path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.locRead('camera_ar_snapshot_failed')),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        file = XFile(path);
      } else {
        await _cameraInitFuture;
        file = await _cameraController!.takePicture();
      }

      // Mavjud stansiyaga rasm: hujjat rejimida bo'lsa ham rasm sifatida qo'shiladi;
      // AI hujjat tahlili — faqat «yangi stansiya» oqimida (stationId == null).
      if (_cameraMode == CameraMode.document && widget.stationId == null) {
        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true)
            .pushNamed('/auto-table-review', arguments: file.path);
        return;
      }

      if (_showScale) {
        file = await ImageUtils.burnScaleBar(
          path: file.path,
          pixelsPerMm: settings.pixelsPerMm,
        );
      }
      if (_isRecording) {
        final path = await _recorder.stop();
        _audioPath = path;
        _isRecording = false;
      }

      if (!mounted) {
        return;
      }
      final repo = context.read<StationRepository>();

      if (widget.stationId != null) {
        final st = repo.getById(widget.stationId!);
        if (st == null) {
          throw StateError('Stansiya topilmadi');
        }
        final existing =
            st.photoPaths ?? (st.photoPath != null ? [st.photoPath!] : []);
        final updatedPhotos = [...existing, file.path];
        final updated = st.copyWith(photoPaths: updatedPhotos);
        await repo.updateStation(
          widget.stationId!,
          updated,
          author: settings.currentUserName,
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.locRead('photo_added')),
            behavior: SnackBarBehavior.floating));
        Navigator.of(context).pop();
        return;
      }

      final locService = context.read<LocationService>();
      await locService.refreshLocation();
      Position? pos = locService.currentPosition;
      pos ??= await Geolocator.getLastKnownPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.locRead('photo_saved_limited_gps')),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // GPS yo‘q — yoki rasm yoki 0,0. Foydalanuvchi rasmni olishi muhim.
        pos = Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 99999,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      final now = DateTime.now();
      final datePart =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final seqPart =
          (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
      final projectCode = (settings.currentProject.length >= 3
          ? settings.currentProject.substring(0, 3).toUpperCase()
          : settings.currentProject.toUpperCase());
      final stationName = '$projectCode-$datePart-$seqPart';

      final station = Station(
        name: stationName,
        lat: pos.latitude,
        lng: pos.longitude,
        altitude: pos.altitude,
        strike: _strike,
        dip: _dip,
        azimuth: _azimuth,
        date: DateTime.now(),
        photoPath: file.path,
        audioPath: _audioPath,
        accuracy: pos.accuracy,
        photoPaths: [file.path],
        project: settings.currentProject,
        dipDirection: GeologyUtils.calculateDipDirection(_strike),
        confidence: 5,
        authorName: settings.currentUserName,
        authorRole: settings.expertMode ? 'Professional' : null,
      );
      final id = await repo.addStation(station);

      if (!mounted) {
        return;
      }
      context.read<TrackService>().recordStationSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.locRead('station_saved')),
          behavior: SnackBarBehavior.floating));
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/station', arguments: id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.locRead('camera_error')}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _formatRecordDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ——— UI qisqichlari ———
  void _checkShowTutorial() {
    final settings = context.read<SettingsController>();
    if (settings.hasSeenCameraTutorial) {
      return;
    }
    _presentCameraTutorial(onFinish: () => settings.hasSeenCameraTutorial = true);
  }

  void _presentCameraTutorial({required VoidCallback onFinish}) {
    final targets = [
      TutorialService.createTarget(
        key: _modeToggleKey,
        identify: "mode_toggle",
        title: "Kamera Rejimi",
        description:
            "Geologik o'lchovlar va Hujjatlarni skanerlash rejimi orasida almashing.",
      ),
      TutorialService.createTarget(
        key: _sensorLockButtonKey,
        identify: "sensor_lock",
        title: "Sensor Lock",
        description:
            "O'lchovlarni muzlatish va tahlil qilish uchun foydalaning.",
      ),
      TutorialService.createTarget(
        key: _shutterButtonKey,
        identify: "shutter",
        title: "Capture & AI",
        description:
            "Rasmga oling va avtomatik AI tahlilini (Lithology) ishga tushiring.",
        align: ContentAlign.top,
      ),
      TutorialService.createTarget(
        key: _menuButtonKey,
        identify: "pro_menu",
        title: "PRO",
        description:
            "Qo'shimcha sozlamalar va ekspert parametrlarini shu yerda oching.",
        align: ContentAlign.left,
      ),
    ];

    TutorialService.showTutorial(
      context,
      targets: targets,
      onFinish: onFinish,
    );
  }

  Widget _buildGuideChip() {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: InkWell(
            onTap: () => _presentCameraTutorial(onFinish: () {}),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
              ),
              child: Text(
                context.loc('camera_guide_button'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setFlashMode(FlashMode mode) async {
    if (_geologicalArActive) {
      if (kIsWeb) {
        return;
      }
      try {
        if (mode == FlashMode.torch) {
          final ok = await TorchLight.isTorchAvailable();
          if (ok) {
            await TorchLight.enableTorch();
          } else {
            throw StateError('no_torch');
          }
        } else {
          await TorchLight.disableTorch();
        }
        if (mounted) {
          setState(() => _flashMode = mode);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.locRead('camera_ar_torch_unavailable')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }
    try {
      await _cameraController?.setFlashMode(mode);
      if (mounted) {
        setState(() => _flashMode = mode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.locRead('camera_error')}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _applyZoom(double zoom) async {
    final c = _cameraController;
    final clamped = zoom.clamp(1.0, 8.0);
    if (c == null || !c.value.isInitialized) {
      if (mounted) {
        setState(() => _zoom = clamped);
      }
      return;
    }
    try {
      await c.setZoomLevel(clamped);
      if (mounted) {
        setState(() => _zoom = clamped);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.locRead('camera_error')}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _disposeCameraOnly() {
    _delayedCameraInitTimer?.cancel();
    _delayedCameraInitTimer = null;
    _cameraController?.dispose();
    _cameraController = null;
    _cameraInitFuture = null;
  }

  static const _kCameraResumeDelayAfterAr = Duration(milliseconds: 480);

  void _scheduleCameraInitAfterArRelease() {
    _delayedCameraInitTimer?.cancel();
    _delayedCameraInitTimer = Timer(_kCameraResumeDelayAfterAr, () {
      _delayedCameraInitTimer = null;
      if (!mounted || _geologicalArActive || _cameraController != null) {
        return;
      }
      _beginCameraInitIfNeeded();
    });
  }

  void _beginCameraInitIfNeeded() {
    if (_cameraController != null || _geologicalArActive || !mounted) {
      return;
    }
    if (_cameraInitInFlight != null) {
      return;
    }
    _cameraInitInFlight = _initCamera().whenComplete(() {
      _cameraInitInFlight = null;
    });
  }

  void _syncCameraToMode() {
    if (!mounted) {
      return;
    }
    if (_geologicalArActive) {
      _delayedCameraInitTimer?.cancel();
      _delayedCameraInitTimer = null;
      _disposeCameraOnly();
      return;
    }
    unawaited(_disableHardwareTorch());
    if (_cameraController != null) {
      _pendingDelayedCameraInitAfterAr = false;
      return;
    }
    if (_pendingDelayedCameraInitAfterAr) {
      _pendingDelayedCameraInitAfterAr = false;
      _scheduleCameraInitAfterArRelease();
      return;
    }
    _beginCameraInitIfNeeded();
  }

  Widget _buildCameraPreview() {
    if (_geologicalArActive) {
      return GeologicalArView(
        key: const ValueKey<Object>('geological_ar_view'),
        onControllerReady: (c) {
          if (!mounted) {
            return;
          }
          setState(() => _arSessionController = c);
        },
        onDisposed: () {
          if (!mounted) {
            return;
          }
          setState(() => _arSessionController = null);
        },
        onArSessionStalled: () {
          if (!mounted) {
            return;
          }
          final s = _settings;
          if (s != null && s.geologicalArEnabled) {
            _pendingDelayedCameraInitAfterAr = true;
            s.geologicalArEnabled = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(context.locRead('camera_ar_session_stalled')),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() {});
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _syncCameraToMode());
          }
        },
      );
    }
    if (_cameraController == null || _cameraInitFuture == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1976D2)));
    }
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${context.locRead('camera_error')}: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        final cam = _cameraController;
        if (cam == null || !cam.value.isInitialized) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }
        return CameraPreview(cam);
      },
    );
  }

  Widget _buildLevelIndicator() {
    if (_cameraMode == CameraMode.document) {
      return const SizedBox.shrink();
    }
    final live = _mag != null && _gravity != null;
    return IgnorePointer(
      child: FocusModeGeologyOverlay(
        pitch: live ? _pitch : _lastHudPitch,
        roll: live ? _roll : _lastHudRoll,
        strike: live ? _strike : _lastHudStrike,
        dip: live ? _dip : _lastHudDip,
        azimuth: _azimuth,
        gravity: live ? _gravity : null,
        isDark: isDark,
      ),
    );
  }

  Widget _buildDocumentHint() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Text(
            context.loc('document_align_hint'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = context.read<SettingsController>();
    _locationService = context.read<LocationService>();
    if (!_appliedInitialUserPrefs) {
      _appliedInitialUserPrefs = true;
      _showCalibrationHint = !_settings!.hasDismissedCalibration;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.stationId != null) {
      _cameraMode = CameraMode.geological;
    }
    WidgetsBinding.instance.addObserver(this);
    _startSensors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowTutorial();
      _syncCameraToMode();
    });
  }

  @override
  void deactivate() {
    _stopSensors();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _stopSensors();
    unawaited(_disableHardwareTorch());
    _disposeCameraOnly();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_disableHardwareTorch());
      _disposeCameraOnly();
      _stopSensors();
    } else if (state == AppLifecycleState.resumed) {
      _startSensors();
      _syncCameraToMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final expertMode = settings.expertMode;
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: widget.embedded
          ? null
          : const AppBottomNavBar(activeRoute: '/camera'),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildCameraPreview()),
            CameraTopBar(
              cameraMode: _cameraMode,
              onModeChanged: (mode) {
                final leavingArUi =
                    _geologicalArActive && mode == CameraMode.document;
                setState(() => _cameraMode = mode);
                if (leavingArUi) {
                  _pendingDelayedCameraInitAfterAr = true;
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _syncCameraToMode());
              },
              isDark: isDark,
              glassBorder: glassBorder,
              textColor: textColor,
              subTextColor: subTextColor,
              allowDocumentMode: widget.stationId == null,
              modeToggleKey: _modeToggleKey,
            ),
            if (_cameraMode == CameraMode.geological)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 50,
                left: 0,
                right: 0,
                child: Center(child: _buildGuideChip()),
              ),
            if (_cameraMode == CameraMode.geological && _showHud && !_geologicalArActive)
              _buildLevelIndicator(),
            if (_cameraMode == CameraMode.document) ...[
              const CameraDocumentViewfinder(),
              _buildDocumentHint(),
            ],
            Positioned(
              right: 12,
              top: MediaQuery.paddingOf(context).top +
                  (_cameraMode == CameraMode.geological ? 50 : 64),
              bottom: AppBottomNavBar.overlayClearanceAboveNav(context) + 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: CameraSideControls(
                  cameraMode: _cameraMode,
                  showScale: _showScale,
                  highSensitivityHorizon: _highSensitivityHorizon,
                  expertMode: expertMode,
                  showHud: _showHud,
                  geologicalArEnabled: settings.geologicalArEnabled,
                  showGeologicalArOption: geologicalArSupportedPlatform(),
                  flashMode: _flashMode,
                  zoom: _zoom,
                  isDark: isDark,
                  glassColor: glassColor,
                  glassBorder: glassBorder,
                  textColor: textColor,
                  onShowScaleChanged: (v) => setState(() => _showScale = v),
                  onHighSenseChanged: (v) =>
                      setState(() => _highSensitivityHorizon = v),
                  onExpertModeChanged: (v) {
                    context.read<SettingsController>().expertMode = v;
                  },
                  onHudToggle: (v) => setState(() => _showHud = v),
                  onGeologicalArChanged: (v) {
                    context.read<SettingsController>().geologicalArEnabled = v;
                    if (!v) {
                      _pendingDelayedCameraInitAfterAr = true;
                    }
                    setState(() {});
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _syncCameraToMode());
                  },
                  onFlashModeChanged: (mode) => _setFlashMode(mode),
                  onZoomChanged: _applyZoom,
                  sensorLockButtonKey: _sensorLockButtonKey,
                  menuButtonKey: _menuButtonKey,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppBottomNavBar.overlayClearanceAboveNav(context),
              child: CameraBottomControls(
                isRecording: _isRecording,
                recordSeconds: _recordSeconds,
                isBusy: _isBusy,
                compassQuality: _compassQuality,
                isDark: isDark,
                glassColor: glassColor,
                textColor: textColor,
                onToggleRecording: _toggleRecording,
                onCapture: () {
                  if (_isBusy) {
                    return;
                  }
                  if (_compassQuality < 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(context.locRead('compass_unreliable_warn')),
                        backgroundColor:
                            StatusSemantics.colorFor(StatusLevel.danger),
                      ),
                    );
                    HapticFeedback.heavyImpact();
                  } else {
                    _capture();
                  }
                },
                formatDuration: _formatRecordDuration,
                shutterButtonKey: _shutterButtonKey,
              ),
            ),
            if (_showScale && _cameraMode == CameraMode.geological)
              const CameraRulerOverlay(),
            if (_showCalibrationHint &&
                _showHud &&
                _cameraMode == CameraMode.geological)
              CameraCalibrationOverlay(onConfirm: () {
                context.read<SettingsController>().hasDismissedCalibration =
                    true;
                setState(() => _showCalibrationHint = false);
                HapticFeedback.heavyImpact();
              }),
          ],
        ),
      ),
    );
  }
}
