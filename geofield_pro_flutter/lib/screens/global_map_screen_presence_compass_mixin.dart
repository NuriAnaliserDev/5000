part of 'global_map_screen.dart';

mixin GlobalMapPresenceCompassMixin on GlobalMapScreenStateFields {
  void _onGpsForFollow() {
    if (!mounted) {
      return;
    }
    final p = _locationForFollow?.currentPosition;
    if (p != null && !_didAutoCenterFromGps && widget.initLocation == null) {
      _didAutoCenterFromGps = true;
      final lat = p.latitude;
      final lng = p.longitude;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        try {
          _mapController.move(LatLng(lat, lng), 14);
        } catch (e) {
          unawaited(
            ProductionDiagnostics.gps(
              'map_initial_center_move_failed',
              data: {'error': e.toString()},
            ),
          );
        }
      });
    }
    if (!_followGps) {
      return;
    }
    if (p == null) {
      return;
    }
    try {
      _mapController.move(
        LatLng(p.latitude, p.longitude),
        _mapController.camera.zoom,
      );
    } catch (e) {
      unawaited(
        ProductionDiagnostics.gps(
          'map_follow_move_failed',
          data: {'error': e.toString()},
        ),
      );
    }
  }

  void _startPresenceBroadcast() {
    final settings = context.read<SettingsController>();
    final presence = context.read<PresenceService>();
    presence.startBroadcasting(
      () {
        final pos = context.read<LocationService>().currentPosition;
        return pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : LatLng(_centerLat, _centerLng);
      },
      settings.currentUserName ?? 'Geolog',
      settings.expertMode ? 'Professional' : 'Standard',
    );
  }

  void _checkShowTutorial() {
    if (widget.fieldWorkshopMode) {
      return;
    }
    final settings = context.read<SettingsController>();
    if (settings.hasSeenMapTutorial) return;

    TutorialService.showTutorial(
      context,
      targets: [
        TutorialService.createTarget(
          key: _drawButtonKey,
          identify: "draw_btn",
          title: "Chizish Rejimi",
          description:
              "Bu yerda siz Fault (Uzilmalar), Contact (Kontaklar) va Bedding Trace (Qatlam izlari) chizishingiz mumkin.",
        ),
        TutorialService.createTarget(
          key: _downloadButtonKey,
          identify: "download_btn",
          title: "Oflayn Xaritalar",
          description:
              "Dala sharoitida internet bo'lmaganda ham ishlash uchun xarita hududini yuklab oling.",
        ),
      ],
      onFinish: () => settings.hasSeenMapTutorial = true,
    );
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) {
        return;
      }
      final h = event.heading;
      if (h == null || h.isNaN || !mounted) return;
      final target = h % 360;
      double? currentHeading = _headingNotifier.value;
      if (currentHeading == null) {
        currentHeading = target;
      } else {
        double d = target - currentHeading;
        if (d > 180) d -= 360;
        if (d < -180) d += 360;
        currentHeading = ((currentHeading + d * 0.35) % 360 + 360) % 360;
      }
      final now = DateTime.now();
      if (now.difference(_lastHeadingUiUpdate).inMilliseconds >= 80) {
        _lastHeadingUiUpdate = now;
        _headingNotifier.value = currentHeading;
      }
    });
  }

  Future<void> _initMap() async {
    _tileProvider = FMTCTileProvider(
      stores: const {
        'opentopomap': BrowseStoreStrategy.readUpdateCreate,
        'osm': BrowseStoreStrategy.readUpdateCreate,
        'satellite': BrowseStoreStrategy.readUpdateCreate,
      },
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );
  }
}
