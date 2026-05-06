part of '../station_summary_screen.dart';

/// Stansiya tahriri holati — forma, xarita va media maydonlari.
mixin StationSummaryStateFields on State<StationSummaryScreen> {
  Station? _station;
  late final FMTCTileProvider _tileProvider;

  String _rockType = 'Magmatik';
  String _subRockType = 'Granit';
  String _measurementType = 'bedding';
  String _subMeasurementType = 'inclined';

  late final TextEditingController _descriptionController;
  late final TextEditingController _rockTypeController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _strikeController;
  late final TextEditingController _dipController;
  late final TextEditingController _azimuthController;
  late final TextEditingController _structureController;
  late final TextEditingController _colorController;
  late final TextEditingController _sampleIdController;
  late final TextEditingController _sampleTypeController;
  late final TextEditingController _dipDirectionController;

  int _confidence = 5;
  String _munsellColor = 'N 8';
  List<Measurement> _measurements = [];
  bool _isAiLoading = false;
  String _coordinateFormat = 'DD';

  final List<String> _measurementTypes = [
    'bedding',
    'cleavage',
    'lineation',
    'joint',
    'contact',
    'other'
  ];
}
