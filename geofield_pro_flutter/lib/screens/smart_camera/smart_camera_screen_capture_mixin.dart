part of 'smart_camera_screen.dart';

/// Audio yozuv, suratga olish va stansiya saqlash — [SmartCameraScreenState] dan ajratilgan.
mixin SmartCameraCaptureMixin on SmartCameraStateFields {
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
                  onPressed: () => ctx.pop(),
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
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
  }

  Future<void> _capture() async {
    if (_isBusy) {
      return;
    }
    if (!mounted) {
      return;
    }
    String? orphanPhotoPath;
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
        final fut = _cameraInitFuture;
        if (fut != null) {
          await fut;
        }
        final cam = _cameraController;
        if (cam == null || !cam.value.isInitialized) {
          if (!mounted) return;
          throw StateError(context.locRead('camera_error'));
        }
        file = await cam.takePicture();
      }

      if (_cameraMode == CameraMode.document && widget.stationId == null) {
        if (!mounted) return;
        AppRouter.pushAutoTableReview(context, file.path);
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
        context.pop();
        return;
      }

      orphanPhotoPath = file.path;

      final imageFile = File(file.path);
      if (!await imageFile.exists()) {
        throw StateError('capture_photo_missing');
      }
      final fileBytes = await imageFile.readAsBytes();
      final shaHex = sha256.convert(fileBytes).toString();

      final captureWallMs = DateTime.now().millisecondsSinceEpoch;

      final prevWall = settings.lastCaptureWallMsForDedup;
      settings.setLastCaptureWallMsForDedup(captureWallMs);

      if (!mounted) {
        return;
      }
      final locService = context.read<LocationService>();
      await locService.refreshLocation();
      Position? pos = locService.currentPosition;
      var locationSource = FieldTrustMeta.sourceLiveRefresh;
      if (pos == null) {
        pos = await Geolocator.getLastKnownPosition();
        locationSource = FieldTrustMeta.sourceLastKnown;
      }

      var online = false;
      try {
        final cc = await Connectivity().checkConnectivity();
        online = cc.any((e) => e != ConnectivityResult.none);
      } catch (_) {}

      final captureId = const Uuid().v4();
      final sessionId = settings.fieldSessionId;

      late final double capLat;
      late final double capLng;
      late final double capAlt;
      late final double? capAccuracy;

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
        capLat = 0;
        capLng = 0;
        capAlt = 0;
        capAccuracy = null;
      } else {
        capLat = pos.latitude;
        capLng = pos.longitude;
        capAlt = pos.altitude;
        capAccuracy = pos.accuracy;
      }

      final dupId = repo.findDuplicateImageHashInSession(
        sessionId: sessionId,
        imageSha256: shaHex,
      );

      final trustMeta = ObservationPipelineService.buildCaptureTrustMeta(
        pos: pos,
        locationSource: pos == null ? null : locationSource,
        captureWallClockMs: captureWallMs,
        fieldSessionId: sessionId,
        captureId: captureId,
        networkConnected: online,
        batteryPct: null,
        lastCaptureEpochMs: prevWall,
        imageSha256: shaHex,
        imageSizeBytes: fileBytes.length,
        duplicateSessionImageHashMatchCaptureId: dupId,
        lastSuccessImageSha256: settings.lastSuccessfulImageSha256,
        lastSuccessCaptureWallMs: settings.lastSuccessfulCaptureWallMs,
      );

      final now = DateTime.now();
      final datePart =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final seqPart = now.millisecondsSinceEpoch.toString();
      final projectCode = (settings.currentProject.length >= 3
          ? settings.currentProject.substring(0, 3).toUpperCase()
          : settings.currentProject.toUpperCase());
      final stationName = '$projectCode-$datePart-$seqPart';

      final station = ObservationPipelineService.createObservation(
        Station(
          name: stationName,
          lat: capLat,
          lng: capLng,
          altitude: capAlt,
          strike: _strike,
          dip: _dip,
          azimuth: _azimuth,
          date: DateTime.now(),
          photoPath: file.path,
          audioPath: _audioPath,
          accuracy: capAccuracy,
          photoPaths: [file.path],
          project: settings.currentProject,
          dipDirection: GeologyUtils.calculateDipDirection(_strike),
          confidence: 5,
          authorName: settings.currentUserName,
          authorRole: settings.expertMode ? 'Professional' : null,
          fieldTrustMetaJson: null,
        ),
        meta: trustMeta,
      );

      FieldCaptureAtomic.markInflight(
        settings,
        captureId: captureId,
        startedMs: captureWallMs,
        sessionId: sessionId,
        photoPath: file.path,
      );
      late final int id;
      try {
        id = await repo.addStation(station);
      } finally {
        FieldCaptureAtomic.clearInflight(settings);
      }

      settings.recordSuccessfulCaptureStamp(
        wallMs: captureWallMs,
        imageSha256: shaHex,
      );

      if (!mounted) {
        return;
      }
      context.read<TrackService>().recordStationSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.locRead('station_saved')),
          behavior: SnackBarBehavior.floating));
      AppRouter.goStation(context, stationId: id);
    } catch (e) {
      await FieldCaptureAtomic.logFailedCapture(
        orphanPhotoPath,
        e,
      );
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
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

  void _startLithologyLoop() {
    _lithologyTimer?.cancel();
    _lithologyTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted || _cameraMode != CameraMode.lithology) {
        timer.cancel();
        return;
      }
      if (!_isLithologyAnalyzing) {
        _runLithologyFrame();
      }
    });
    _runLithologyFrame();
  }

  Future<void> _runLithologyFrame() async {
    if (!mounted ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isLithologyAnalyzing = true);
    try {
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);

      final service = AiLithologyService();
      final result = await service
          .analyzeRockSample(file)
          .timeout(const Duration(seconds: 40));

      if (mounted && _cameraMode == CameraMode.lithology) {
        setState(() => _currentLithology = result);
      }

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
