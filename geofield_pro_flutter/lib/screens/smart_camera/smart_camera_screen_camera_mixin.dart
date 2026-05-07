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
    unawaited(
      ProductionDiagnostics.camera(
        'init_begin',
        data: {
          'embedded': widget.embedded,
          'surface_active': _cameraSurfaceActive,
        },
      ),
    );
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          unawaited(ProductionDiagnostics.camera('permission_denied'));
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

      final cameras = await availableCameras()
          .timeout(
        AppTimeouts.availableCamerasLookup,
        onTimeout: () => <CameraDescription>[],
      );
      if (!mounted || !_cameraSurfaceActive) {
        return;
      }
      if (cameras.isEmpty) {
        unawaited(ProductionDiagnostics.camera('no_cameras_listed'));
        throw StateError('Kamera topilmadi');
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      const presets = <ResolutionPreset>[
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];
      Object? lastError;
      for (final preset in presets) {
        if (!mounted || !_cameraSurfaceActive) {
          return;
        }
        _cameraController?.dispose();
        _cameraController = null;
        _cameraInitFuture = null;
        try {
          unawaited(
            ProductionDiagnostics.camera(
              'preset_attempt',
              phase: preset.name,
            ),
          );
          final controller = CameraController(
            backCamera,
            preset,
            enableAudio: false,
          );
          _cameraController = controller;
          _cameraInitFuture = controller
              .initialize()
              .timeout(AppTimeouts.cameraInitPerPresetAttempt);
          await _cameraInitFuture;
          if (!mounted || !_cameraSurfaceActive) {
            unawaited(ProductionDiagnostics.camera('init_aborted_after_init'));
            _disposeCameraOnly();
            return;
          }
          if (controller.value.isInitialized) {
            unawaited(
              ProductionDiagnostics.camera(
                'init_success',
                phase: preset.name,
              ),
            );
            if (mounted) {
              setState(() {});
            }
            return;
          }
        } catch (e) {
          unawaited(
            ProductionDiagnostics.camera(
              'preset_failed',
              phase: preset.name,
              data: {'error': e.toString()},
            ),
          );
          lastError = e;
          _disposeCameraOnly();
        }
      }
      throw lastError ?? StateError('Kamera ishga tushmadi');
    } catch (e) {
      unawaited(
        ProductionDiagnostics.camera(
          'init_failed',
          data: {'error': e.toString()},
        ),
      );
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
    _cachedCameraPermissionFuture = null;
    _cameraPreviewSession++;
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

  Widget _cameraInactivePlaceholder() {
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.45), size: 56),
            const SizedBox(height: 12),
            Text(
              'Kamera hozir faol emas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraSurfaceActive) {
      return _cameraInactivePlaceholder();
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
      _cachedCameraPermissionFuture ??= Permission.camera.status;
      return KeyedSubtree(
        key: ValueKey<String>('cam_perm_$_cameraPreviewSession'),
        child: FutureBuilder<PermissionStatus>(
          future: _cachedCameraPermissionFuture,
          builder: (context, snap) {
            final denied = snap.hasData &&
                (snap.data == PermissionStatus.denied ||
                    snap.data == PermissionStatus.permanentlyDenied);
            if (denied) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt,
                        color: Colors.white38, size: 64),
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
        ),
      );
    }
    return KeyedSubtree(
      key: ValueKey<int>(_cameraPreviewSession),
      child: FutureBuilder<void>(
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
        if (cam == null) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }
        try {
          if (!cam.value.isInitialized) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }
          return CameraPreview(cam);
        } catch (e, _) {
          unawaited(
            ProductionDiagnostics.camera(
              'preview_stale_controller',
              data: {'error': e.toString()},
            ),
          );
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }
      },
    ),
    );
  }
}
