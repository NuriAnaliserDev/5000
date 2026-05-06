part of 'smart_camera_screen.dart';

/// HUD ranglari, tutorial va kichik overlay vidjetlari.
mixin SmartCameraPresentationMixin on SmartCameraStateFields {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => Colors.white;
  Color get subTextColor => Colors.white70;
  List<Shadow> get textShadows => [
        const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
        const Shadow(color: Colors.black, blurRadius: 10),
      ];
  Color get glassColor => Colors.black.withValues(alpha: 0.5);
  Color get glassBorder => Colors.white.withValues(alpha: 0.2);

  void _checkShowTutorial() {
    final settings = context.read<SettingsController>();
    if (settings.hasSeenCameraTutorial) {
      return;
    }
    _presentCameraTutorial(
        onFinish: () => settings.hasSeenCameraTutorial = true);
  }

  void _presentCameraTutorial({required VoidCallback onFinish}) {
    final targets = [
      TutorialService.createTarget(
        key: _modeToggleKey,
        identify: "mode_toggle",
        title: "Kamera Rejimi",
        description:
            "Geologik o'lchovlar va Hujjatlarni skanerlash rejimi orasida almashing.",
      ),
      TutorialService.createTarget(
        key: _sensorLockButtonKey,
        identify: "sensor_lock",
        title: "Sensor Lock",
        description:
            "O'lchovlarni muzlatish va tahlil qilish uchun foydalaning.",
      ),
      TutorialService.createTarget(
        key: _shutterButtonKey,
        identify: "shutter",
        title: "Capture & AI",
        description:
            "Rasmga oling va avtomatik AI tahlilini (Lithology) ishga tushiring.",
        align: ContentAlign.top,
      ),
      TutorialService.createTarget(
        key: _menuButtonKey,
        identify: "pro_menu",
        title: "PRO",
        description:
            "Qo'shimcha sozlamalar va ekspert parametrlarini shu yerda oching.",
        align: ContentAlign.left,
      ),
    ];

    TutorialService.showTutorial(
      context,
      targets: targets,
      onFinish: onFinish,
    );
  }

  Widget _buildGuideChip() {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: InkWell(
            onTap: () => _presentCameraTutorial(onFinish: () {}),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
              ),
              child: Text(
                context.loc('camera_guide_button'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator() {
    if (_cameraMode == CameraMode.document) {
      return const SizedBox.shrink();
    }
    final live = _mag != null && _gravity != null;
    return IgnorePointer(
      child: FocusModeGeologyOverlay(
        pitch: live ? _pitch : _lastHudPitch,
        roll: live ? _roll : _lastHudRoll,
        strike: live ? _strike : _lastHudStrike,
        dip: live ? _dip : _lastHudDip,
        azimuth: _azimuth,
        gravity: live ? _gravity : null,
        isDark: isDark,
      ),
    );
  }

  Widget _buildDocumentHint() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Text(
            context.loc('document_align_hint'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
