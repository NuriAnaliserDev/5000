part of 'smart_camera_screen.dart';

class SmartCameraScreenState extends State<SmartCameraScreen>
    with
        SmartCameraStateFields,
        WidgetsBindingObserver,
        SmartCameraSensorMixin,
        SmartCameraCaptureMixin,
        SmartCameraCameraMixin,
        SmartCameraPresentationMixin {
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
      //_checkShowTutorial();
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
    _lithologyTimer?.cancel();
    _lithologyTimer = null;
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
      unawaited(ProductionDiagnostics.camera('lifecycle_pause'));
      _lithologyTimer?.cancel();
      _lithologyTimer = null;
      unawaited(_disableHardwareTorch());
      _disposeCameraOnly();
      _stopSensors();
    } else if (state == AppLifecycleState.resumed) {
      _cachedCameraPermissionFuture = null;
      unawaited(ProductionDiagnostics.camera('lifecycle_resume'));
      _startSensors();
      _ensureCameraMatchesMode();
      if (_cameraMode == CameraMode.lithology) {
        _startLithologyLoop();
      }
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
                final leavingArUi = (_geologicalArActive ||
                        _cameraMode == CameraMode.lithology) &&
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
                top: MediaQuery.paddingOf(context).top + 58,
                left: 12,
                child: _buildGuideChip(),
              ),
            if (_cameraMode == CameraMode.geological &&
                _showHud &&
                !_geologicalArActive)
              _buildLevelIndicator(),
            if (_cameraMode == CameraMode.document) ...[
              const CameraDocumentViewfinder(),
              _buildDocumentHint(),
            ],
            if (_cameraMode == CameraMode.lithology && AppFeatures.enableAR)
              LithologyArOverlay(
                result: _currentLithology,
                userContext: UserContext(
                  role: _settings?.expertMode == true
                      ? UserRole.expert
                      : UserRole.junior,
                  mode: AppMode.exploration,
                ),
                onReset: () => setState(() => _currentLithology = null),
                onManualInput: () {
                  if (_currentLithology != null) {
                    _capture();
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
                  showGeologicalArOption:
                      geologicalArSupportedPlatform() && AppFeatures.enableAR,
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
}
