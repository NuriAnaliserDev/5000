import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../models/station.dart';
import '../models/measurement.dart';
import '../services/station_repository.dart';
import '../services/settings_controller.dart';
import '../services/pdf_export_service.dart';
import '../services/ai_lithology_service.dart';
import '../services/ai/ai_rate_limiter.dart';
import '../utils/app_localizations.dart';
import '../utils/rocks_list.dart';
import '../utils/munsell_data.dart';

// Components
import 'station/components/station_app_bar.dart';
import 'station/components/station_form_body.dart';
import 'station/components/station_map_header.dart';

class StationSummaryScreen extends StatefulWidget {
  final int? stationId;
  const StationSummaryScreen({super.key, this.stationId});

  @override
  State<StationSummaryScreen> createState() => _StationSummaryScreenState();
}

class _StationSummaryScreenState extends State<StationSummaryScreen> {
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

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initMap();
  }

  void _initControllers() {
    _descriptionController = TextEditingController();
    _rockTypeController = TextEditingController();
    _structureController = TextEditingController();
    _colorController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _strikeController = TextEditingController();
    _dipController = TextEditingController();
    _azimuthController = TextEditingController();
    _sampleIdController = TextEditingController();
    _sampleTypeController = TextEditingController();
    _dipDirectionController = TextEditingController();

    _strikeController.addListener(() {
      final s = double.tryParse(_strikeController.text);
      if (s != null) {
        _dipDirectionController.text = ((s + 90) % 360).toStringAsFixed(0);
      }
    });
  }

  void _initMap() {
    _tileProvider = FMTCTileProvider(
      stores: const {
        'opentopomap': BrowseStoreStrategy.readUpdateCreate,
        'osm': BrowseStoreStrategy.readUpdateCreate,
        'satellite': BrowseStoreStrategy.readUpdateCreate,
      },
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_station != null || widget.stationId == null) return;
    _loadStation();
  }

  void _loadStation() {
    final repo = context.read<StationRepository>();
    _station = repo.getById(widget.stationId!);
    if (_station != null) {
      _rockType = 'Magmatik';
      if (_station!.rockType != null) {
        for (var entry in rockTree.entries) {
          if (entry.value.contains(_station!.rockType)) {
            _rockType = entry.key;
            _subRockType = _station!.rockType!;
            break;
          }
        }
      }
      _descriptionController.text = _station!.description ?? '';
      _rockTypeController.text = _station!.rockType ?? '';
      _structureController.text = _station!.structure ?? 'Massiv';
      _colorController.text = _station!.color ?? 'Och kulrang';
      _latController.text = _station!.lat.toStringAsFixed(6);
      _lngController.text = _station!.lng.toStringAsFixed(6);
      _strikeController.text = _station!.strike.toStringAsFixed(0);
      _dipController.text = _station!.dip.toStringAsFixed(0);
      _azimuthController.text = _station!.azimuth.toStringAsFixed(0);
      _dipDirectionController.text =
          _station!.dipDirection?.toStringAsFixed(0) ?? '';
      _sampleIdController.text = _station!.sampleId ?? '';
      _sampleTypeController.text = _station!.sampleType ?? '';
      _confidence = _station!.confidence ?? 5;
      _munsellColor = _station!.munsellColor ?? 'N 8';
      _measurementType = _station!.measurementType ?? _measurementTypes.first;
      _subMeasurementType = _station!.subMeasurementType ?? 'inclined';
      _measurements =
          (_station!.measurements ?? []).cast<Measurement>().toList();
    }
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

  Future<void> _save() async {
    final success = await _saveCore();
    if (success && mounted) Navigator.of(context).pop();
  }

  Future<bool> _saveCore() async {
    if (_station == null) return false;
    final repo = context.read<StationRepository>();
    final parsedLat = double.tryParse(_latController.text.replaceAll(',', '.'));
    final parsedLng = double.tryParse(_lngController.text.replaceAll(',', '.'));

    if (parsedLat == null || parsedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.locRead('lat_lon_error'))));
      return false;
    }

    final updated = _station!.copyWith(
      lat: parsedLat,
      lng: parsedLng,
      strike: double.tryParse(_strikeController.text) ?? _station!.strike,
      dip: double.tryParse(_dipController.text) ?? _station!.dip,
      azimuth: double.tryParse(_azimuthController.text) ?? _station!.azimuth,
      rockType: _subRockType,
      measurementType: _measurementType,
      subMeasurementType: _subMeasurementType,
      structure: _structureController.text.trim(),
      color: _colorController.text.trim(),
      description: _descriptionController.text,
      dipDirection: double.tryParse(_dipDirectionController.text),
      sampleId: _sampleIdController.text.trim(),
      sampleType: _sampleTypeController.text.trim(),
      confidence: _confidence,
      munsellColor: _munsellColor,
      measurements: _measurements,
    );

    final author = context.read<SettingsController>().currentUserName;
    await repo.updateStation(_station!.key, updated, author: author);
    return true;
  }

  Future<void> _updateGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final successMsg = context.locRead('success_saved');
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('GPS xatosi: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_station == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    final paths = (_station!.photoPaths ?? []).toList()..add(picked.path);
    final updated = _station!.copyWith(photoPaths: paths);
    final stationRepo = context.read<StationRepository>();
    final author = context.read<SettingsController>().currentUserName;
    await stationRepo.updateStation(_station!.key, updated, author: author);
    if (!mounted) return;
    setState(() => _station = updated);
  }

  Future<void> _deletePhoto(String path) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: Text(context.locRead('delete_photo')), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.locRead('cancel'))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.locRead('delete')))
            ]));
    if (ok != true) return;
    if (!mounted) return;
    final paths = (_station!.photoPaths ?? []).toList()..remove(path);
    final updated = _station!.copyWith(photoPaths: paths);
    final stationRepo = context.read<StationRepository>();
    final author = context.read<SettingsController>().currentUserName;
    await stationRepo.updateStation(_station!.key, updated, author: author);
    if (!mounted) return;
    setState(() => _station = updated);
  }

  void _showMunsellPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Munsell Color Chart'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.6,
            ),
            itemCount: geologicalMunsellColors.length,
            itemBuilder: (c, i) {
              final m = geologicalMunsellColors[i];
              return InkWell(
                onTap: () => Navigator.pop(c, m.code),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  color: Color(m.hex),
                  child: Center(
                    child: Text(
                      m.code,
                      style: const TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (result != null) setState(() => _munsellColor = result);
  }

  Future<void> _playAudio() async {
    final path = _station?.audioPath;
    if (path == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Future<void> _runAiLithology() async {
    if (_station == null) return;
    final paths = <String>[
      ...?_station!.photoPaths,
      if (_station!.photoPath != null && _station!.photoPath!.isNotEmpty)
        _station!.photoPath!,
    ];
    final existing = paths.where((p) => File(p).existsSync()).toList();
    if (existing.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locRead('ai_lithology_need_photo')),
        ),
      );
      return;
    }
    final imagePath = existing.last;

    setState(() => _isAiLoading = true);
    try {
      final result =
          await AiLithologyService().analyzeRockSample(File(imagePath));
      if (!mounted) return;

      final matched = matchRockTreeFromAiLabel(result.rockType);
      final mineralsLine = result.minerals.isEmpty
          ? ''
          : '${context.locRead('ai_lithology_minerals_prefix')} ${result.minerals.join(', ')}';

      setState(() {
        if (matched != null) {
          _rockType = matched.category;
          _subRockType = matched.sub;
          _rockTypeController.text = matched.sub;
        }

        final prev = _descriptionController.text.trim();
        final desc = result.description.trim();
        final tail = mineralsLine.trim();
        final unmatchedType = matched == null && result.rockType.trim().isNotEmpty
            ? '${context.locRead('ai_lithology_verify_type_prefix')} ${result.rockType}'
            : '';
        final parts = <String>[];
        if (prev.isNotEmpty) parts.add(prev);
        if (unmatchedType.isNotEmpty) parts.add(unmatchedType);
        if (desc.isNotEmpty) parts.add(desc);
        if (tail.isNotEmpty) parts.add(tail);
        _descriptionController.text = parts.join('\n\n');

        _confidence = result.confidence.clamp(1, 5);
        _munsellColor = result.munsellColor;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locRead('ai_lithology_applied_hint')),
        ),
      );
    } on QuotaExceededException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.locRead('ai_lithology_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
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
              onViewPhoto: (p) =>
                  Navigator.of(context).pushNamed('/painter', arguments: p),
              onOpenPainter: (p) =>
                  Navigator.of(context).pushNamed('/painter', arguments: p),
              onPlayAudio: _playAudio,
            ),
          ),
        ],
      ),
    );
  }

  /// Aqlli kamera yopilgach stansiyani repodan qayta yuklaymiz — aks holda rasm
  /// [photoPaths] yangilangan bo'lsa ham [setState] eski [Station] qoladi.
  Future<void> _openCameraForStation() async {
    final id = _station?.key;
    await Navigator.of(context).pushNamed('/camera', arguments: id);
    if (!mounted || id == null) {
      return;
    }
    final repo = context.read<StationRepository>();
    final fresh = repo.getById(id);
    if (fresh != null) {
      setState(() => _station = fresh);
    }
  }

  void _confirmDelete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: Text(context.locRead('delete')), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.locRead('cancel'))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.locRead('delete')))
            ]));
    if (!mounted) return;
    if (ok == true) {
      final stationRepo = context.read<StationRepository>();
      await stationRepo.deleteStation(_station!.key);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}
