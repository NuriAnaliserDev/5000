part of 'smart_camera_screen.dart';

/// Kamera sessiyasi: init, sinxronlash, flash/zoom, preview vidjeti.
mixin SmartCameraCameraMixin on SmartCameraStateFields {
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

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (mounted) {
            setState(() {});
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
        setState(() {});
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    }
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
}
