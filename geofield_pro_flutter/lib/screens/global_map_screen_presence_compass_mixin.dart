part of 'global_map_screen.dart';

mixin GlobalMapPresenceCompassMixin on GlobalMapScreenStateFields {
  void _onGpsForFollow() {
    if (!mounted || !_followGps) {
      return;
    }
    final p = _locationForFollow?.currentPosition;
    if (p == null) {
      return;
    }
    _mapController.move(
      LatLng(p.latitude, p.longitude),
      _mapController.camera.zoom,
    );
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

  @override
  void dispose() {
    _locationForFollow?.removeListener(_onGpsForFollow);
    _compassSub?.cancel();
    _headingNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
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
