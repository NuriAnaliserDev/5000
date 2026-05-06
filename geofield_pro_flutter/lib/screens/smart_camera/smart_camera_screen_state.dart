part of 'smart_camera_screen.dart';

class SmartCameraScreenState extends State<SmartCameraScreen>
    with
        SmartCameraStateFields,
        WidgetsBindingObserver,
        SmartCameraSensorMixin,
        SmartCameraCaptureMixin {
  /// Tab ko‘rinishi yoki hayotiy sikl — faqat ochiq tabda sessiya ishga tushadi.
  void _ensureCameraMatchesMode() {
    if (!mounted) {
      return;
    }
    if (!_cameraSurfaceActive) {
      _delayedCameraInitTimer?.cancel();
      _delayedCameraInitTimer = null;
      _disposeCameraOnly();
      return;
    }
    _syncCameraToMode();
  }

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

  Future<void> _initRuntimePermissions() async {
    if (kIsWeb) {
      return;
    }
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();
  }

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
      // Android 6+ (API 23+): runtime permission kerak
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (mounted) {
            setState(() {}); // loading spinner o'chadi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Kamera ruxsati berilmadi. Sozlamalarda yoqing.',
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Sozlamalar',
                  onPressed: openAppSettings,
                ),
              ),
            );
          }
          return;
        }
      }

      final cameras = await availableCameras();
      if (!mounted || !_cameraSurfaceActive) {
        return;
      }
      if (cameras.isEmpty) {
        throw StateError('Kamera topilmadi');
      }
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
      if (!mounted || !_cameraSurfaceActive) {
        _disposeCameraOnly();
        return;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _disposeCameraOnly();
      if (mounted) {
        setState(() {}); // UI ni yangilab error ko'rsatadi
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
  }

  // ——— UI qisqichlari ———
  void _checkShowTutorial() {
    final settings = context.read<SettingsController>();
    if (settings.hasSeenCameraTutorial) {
      return;
    }
    _presentCameraTutorial(
        onFinish: () => settings.hasSeenCameraTutorial = true);
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
        ErrorHandler.show(context, ErrorMapper.map(e));
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
        ErrorHandler.show(context, ErrorMapper.map(e));
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
    if (!_cameraSurfaceActive) {
      return const ColoredBox(color: Colors.black);
    }
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
                content: Text(context.locRead('camera_ar_session_stalled')),
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() {});
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _ensureCameraMatchesMode());
          }
        },
      );
    }
    if (_cameraController == null || _cameraInitFuture == null) {
      // Permission rad etilgan yoki kamera topilmadi — foydalanuvchiga ko'rsatamiz
      return FutureBuilder<PermissionStatus>(
        future: Permission.camera.status,
        builder: (context, snap) {
          final denied = snap.hasData &&
              (snap.data == PermissionStatus.denied ||
                  snap.data == PermissionStatus.permanentlyDenied);
          if (denied) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Kamera ruxsati berilmagan',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Sozlamalarni och'),
                  ),
                ],
              ),
            );
          }
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        },
      );
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
    unawaited(_initRuntimePermissions());
    if (widget.stationId != null) {
      _cameraMode = CameraMode.geological;
    }
    WidgetsBinding.instance.addObserver(this);
    _startSensors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShowTutorial();
      _ensureCameraMatchesMode();
    });
  }

  @override
  void didUpdateWidget(SmartCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.embedded) {
      return;
    }
    if (oldWidget.tabVisible == widget.tabVisible) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureCameraMatchesMode();
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
      _ensureCameraMatchesMode();
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
                    (_geologicalArActive || _cameraMode == CameraMode.lithology) && 
                    mode == CameraMode.document;
                setState(() {
                  _cameraMode = mode;
                  if (mode != CameraMode.lithology) {
                    _lithologyTimer?.cancel();
                    _currentLithology = null;
                  } else {
                    _startLithologyLoop();
                  }
                });
                if (leavingArUi) {
                  _pendingDelayedCameraInitAfterAr = true;
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _ensureCameraMatchesMode());
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
            if (_cameraMode == CameraMode.geological &&
                _showHud &&
                !_geologicalArActive)
              _buildLevelIndicator(),
            if (_cameraMode == CameraMode.document) ...[
              const CameraDocumentViewfinder(),
              _buildDocumentHint(),
            ],
            if (_cameraMode == CameraMode.lithology)
              LithologyArOverlay(
                result: _currentLithology,
                userContext: UserContext(
                  role: _settings?.expertMode == true ? UserRole.expert : UserRole.junior,
                  mode: AppMode.exploration,
                ),
                onReset: () => setState(() => _currentLithology = null),
                onManualInput: () {
                  // Fallback to manual entry screen
                  if (_currentLithology != null) {
                     _capture(); // Use current logic to save and then edit
                  }
                },
                onAccept: _capture,
              ),
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
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _ensureCameraMatchesMode());
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
  void _startLithologyLoop() {
    _lithologyTimer?.cancel();
    // Start periodic analysis every 2.5 seconds (slightly more than throttle to be safe)
    _lithologyTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted || _cameraMode != CameraMode.lithology) {
        timer.cancel();
        return;
      }
      if (!_isLithologyAnalyzing) {
        _runLithologyFrame();
      }
    });
    // Initial run
    _runLithologyFrame();
  }

  Future<void> _runLithologyFrame() async {
    if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() => _isLithologyAnalyzing = true);
    try {
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      
      final service = AiLithologyService();
      final result = await service.analyzeRockSample(file);
      
      if (mounted && _cameraMode == CameraMode.lithology) {
        setState(() => _currentLithology = result);
      }
      
      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('AI_LITHOLOGY_AR_ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => _isLithologyAnalyzing = false);
      }
    }
  }
}
