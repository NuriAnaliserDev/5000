part of 'smart_camera_screen.dart';

/// Barcha holat maydonlari — sensor/kamera/capture mixinlari shu qatlam ustiga quriladi.
mixin SmartCameraStateFields on State<SmartCameraScreen> {
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
  final bool _miniCalibrationDismissed = false;

  AIAnalysisResult? _currentLithology;
  bool _isLithologyAnalyzing = false;
  Timer? _lithologyTimer;
  bool _wasLeveled = false;

  final GlobalKey _sensorLockButtonKey = GlobalKey();
  final GlobalKey _modeToggleKey = GlobalKey();
  final GlobalKey _shutterButtonKey = GlobalKey();
  final GlobalKey _menuButtonKey = GlobalKey();

  GeologicalArSessionController? _arSessionController;

  bool _pendingDelayedCameraInitAfterAr = false;
  Timer? _delayedCameraInitTimer;
  Future<void>? _cameraInitInFlight;

  SettingsController? _settings;
  LocationService? _locationService;
  bool _appliedInitialUserPrefs = false;

  CameraMode _cameraMode = CameraMode.geological;

  bool get _geologicalArActive =>
      AppFeatures.enableAR &&
      _cameraMode == CameraMode.geological &&
      (_settings?.geologicalArEnabled ?? false) &&
      geologicalArSupportedPlatform();

  bool get _cameraSurfaceActive => !widget.embedded || widget.tabVisible;

  double get _headingSmooth => _highSensitivityHorizon ? 0.52 : 0.38;
  double get _azimuthSmooth => _highSensitivityHorizon ? 0.50 : 0.42;
  double get _dipStrikeSmooth => _highSensitivityHorizon ? 0.34 : 0.30;
  double get _horizonSmooth => _highSensitivityHorizon ? 0.60 : 0.40;
}
