part of 'global_map_screen.dart';

/// Global map holati — linework / slice / struktura taqqoslari uchun umumiy maydonlar.
mixin GlobalMapScreenStateFields on State<GlobalMapScreen> {
  late final FMTCTileProvider _tileProvider;
  final MapController _mapController = MapController();

  StreamSubscription<CompassEvent>? _compassSub;
  final ValueNotifier<double?> _headingNotifier = ValueNotifier(null);
  DateTime _lastHeadingUiUpdate = DateTime.now();

  final GlobalKey _drawButtonKey = GlobalKey();
  final GlobalKey _downloadButtonKey = GlobalKey();

  bool _isDrawingMode = false;
  List<LatLng> _drawingPoints = [];
  final List<LatLng> _redoStack = [];
  bool _isEraserMode = false;
  String _selectedLineType = 'fault';
  bool _isCurvedMode = false;
  double _projectionDepth = 0;
  bool _showProjections = false;
  bool _isSnapEnabled = true;

  double _baseLayerOpacity = 1.0;
  double _gisLayerOpacity = 0.6;
  double _drawingLayerOpacity = 1.0;
  bool _showLayerDrawer = false;

  bool _mapFieldMenuOpen = false;

  String? _editingPolygonId;
  int? _selectedVertexIndex;
  bool _isVertexEditMode = false;

  bool _isSliceMode = false;

  bool _isStructurePlaceMode = false;

  bool _isMeasureMode = false;
  final List<LatLng> _measurePoints = [];
  final List<bool> _workshopChecklist = [false, false, false];

  double _centerLat = 41.2995;
  double _centerLng = 69.2401;

  bool _followGps = false;
  LocationService? _locationForFollow;
  /// Birinchi real GPS fix dan keyin xaritani Toshkent fallbackdan chiqarish.
  bool _didAutoCenterFromGps = false;

  bool _workshopInfoBanner = true;
}
