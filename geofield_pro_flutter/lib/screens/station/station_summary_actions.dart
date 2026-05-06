part of '../station_summary_screen.dart';

/// Saqlash, GPS, foto/audio, AI lithology, o‘chirish — forma bilan bog‘liq harakatlar.
mixin StationSummaryActionsMixin on StationSummaryStateFields {
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

  Future<void> _save() async {
    final success = await _saveCore();
    if (success && mounted) context.pop();
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
      ErrorHandler.show(context, ErrorMapper.map(e));
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
                  onPressed: () => ctx.pop(false),
                  child: Text(context.locRead('cancel'))),
              TextButton(
                  onPressed: () => ctx.pop(true),
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
                onTap: () => Navigator.of(ctx).pop(m.code),
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
      final mineralsLine = result.mineralogy.isEmpty
          ? ''
          : '${context.locRead('ai_lithology_minerals_prefix')} ${result.mineralogy.join(', ')}';

      setState(() {
        if (matched != null) {
          _rockType = matched.category;
          _subRockType = matched.sub;
          _rockTypeController.text = matched.sub;
        }

        final prev = _descriptionController.text.trim();
        final desc = result.notes.trim();
        final tail = mineralsLine.trim();
        final unmatchedType = matched == null &&
                result.rockType.trim().isNotEmpty
            ? '${context.locRead('ai_lithology_verify_type_prefix')} ${result.rockType}'
            : '';
        final parts = <String>[];
        if (prev.isNotEmpty) parts.add(prev);
        if (unmatchedType.isNotEmpty) parts.add(unmatchedType);
        if (desc.isNotEmpty) parts.add(desc);
        if (tail.isNotEmpty) parts.add(tail);
        _descriptionController.text = parts.join('\n\n');

        _confidence = result.confidence.clamp(1, 5).toInt();
        _munsellColor = result.munsellApprox;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locRead('ai_lithology_applied_hint')),
        ),
      );
    } on QuotaExceededException catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  /// Aqlli kamera yopilgach stansiyani repodan qayta yuklaymiz — aks holda rasm
  /// [photoPaths] yangilangan bo'lsa ham [setState] eski [Station] qoladi.
  Future<void> _openCameraForStation() async {
    final id = _station?.key;
    final sid = id is int ? id : null;
    if (sid == null) return;
    MainTabNavigation.openCamera(context, stationId: sid);
    for (final d in [
      const Duration(milliseconds: 1200),
      const Duration(seconds: 4)
    ]) {
      Future<void>.delayed(d, () {
        if (!mounted) return;
        final repo = context.read<StationRepository>();
        final fresh = repo.getById(sid);
        if (fresh != null) {
          setState(() => _station = fresh);
        }
      });
    }
  }

  void _confirmDelete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: Text(context.locRead('delete')), actions: [
              TextButton(
                  onPressed: () => ctx.pop(false),
                  child: Text(context.locRead('cancel'))),
              TextButton(
                  onPressed: () => ctx.pop(true),
                  child: Text(context.locRead('delete')))
            ]));
    if (!mounted) return;
    if (ok == true) {
      final stationRepo = context.read<StationRepository>();
      await stationRepo.deleteStation(_station!.key);
      if (!mounted) return;
      context.pop();
    }
  }
}
