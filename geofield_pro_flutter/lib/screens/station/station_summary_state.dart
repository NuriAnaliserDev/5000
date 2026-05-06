part of '../station_summary_screen.dart';

class _StationSummaryScreenState extends State<StationSummaryScreen>
    with StationSummaryStateFields, StationSummaryActionsMixin {
  @override
  void initState() {
    super.initState();
    _initControllers();
    _initMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_station != null || widget.stationId == null) return;
    _loadStation();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _descriptionController.dispose();
    _rockTypeController.dispose();
    _structureController.dispose();
    _colorController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _strikeController.dispose();
    _dipController.dispose();
    _azimuthController.dispose();
    _sampleIdController.dispose();
    _sampleTypeController.dispose();
    _dipDirectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StationAppBar(
        station: _station,
        onSave: _save,
        onMenuAction: (val) {
          if (val == 'pdf' && _station != null) {
            PdfExportService.generateStationReport(_station!)
                .then((file) => Share.shareXFiles([XFile(file.path)]));
          }
          if (val == 'delete' && _station != null) {
            _confirmDelete();
          }
        },
      ),
      body: Column(
        children: [
          StationMapHeader(
              station: _station,
              currentStyle: context.watch<SettingsController>().mapStyle,
              tileProvider: _tileProvider),
          Expanded(
            child: StationFormBody(
              station: _station,
              descriptionController: _descriptionController,
              rockTypeController: _rockTypeController,
              structureController: _structureController,
              colorController: _colorController,
              latController: _latController,
              lngController: _lngController,
              strikeController: _strikeController,
              dipController: _dipController,
              dipDirectionController: _dipDirectionController,
              azimuthController: _azimuthController,
              sampleIdController: _sampleIdController,
              sampleTypeController: _sampleTypeController,
              rockType: _rockType,
              measurementType: _measurementType,
              subMeasurementType: _subMeasurementType,
              measurementTypes: _measurementTypes,
              confidence: _confidence,
              munsellColor: _munsellColor,
              isAiLoading: _isAiLoading,
              isPlaying: _isPlaying,
              coordinateFormat: _coordinateFormat,
              onRockTypeChanged: (v) =>
                  setState(() => _rockType = v ?? 'Magmatik'),
              onSubRockTypeChanged: (v) =>
                  setState(() => _subRockType = v ?? ''),
              onAiAnalyze: _runAiLithology,
              onConfidenceChanged: (v) => setState(() => _confidence = v),
              onPickMunsell: _showMunsellPicker,
              onMeasurementTypeChanged: (v) =>
                  setState(() => _measurementType = v ?? 'bedding'),
              onSubMeasurementTypeChanged: (v) =>
                  setState(() => _subMeasurementType = v ?? 'inclined'),
              onUpdateGps: _updateGps,
              onCoordinateFormatChanged: (v) =>
                  setState(() => _coordinateFormat = v),
              onAddCamera: _openCameraForStation,
              onAddGallery: _pickFromGallery,
              onDeletePhoto: _deletePhoto,
              onViewPhoto: (p) => context.push('/painter', extra: p),
              onOpenPainter: (p) => context.push('/painter', extra: p),
              onPlayAudio: _playAudio,
            ),
          ),
        ],
      ),
    );
  }
}
