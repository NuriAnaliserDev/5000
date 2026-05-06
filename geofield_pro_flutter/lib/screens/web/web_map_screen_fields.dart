part of 'web_map_screen.dart';

mixin WebMapScreenFields on State<WebMapScreen> {
  final MapController _mapController = MapController();

  bool _isDrawingMode = false;
  final List<LatLng> _drawingPoints = [];
  ZoneType _selectedZoneType = ZoneType.workArea;
  final TextEditingController _zoneNameCtrl =
      TextEditingController(text: 'Yangi Zona');
  final TextEditingController _zoneDescCtrl = TextEditingController();

  BoundaryPolygon? _editingPolygon;

  Stream<QuerySnapshot<Map<String, dynamic>>>? get _shiftsStreamOrNull =>
      firestoreOrNull?.collectionGroup('shift_logs').snapshots();
}
