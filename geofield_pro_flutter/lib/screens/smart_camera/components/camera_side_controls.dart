import 'dart:ui';

import 'package:camera/camera.dart' show FlashMode;
import 'package:flutter/material.dart';
import '../../../app/app_router.dart';
import '../../../utils/app_localizations.dart';
import '../smart_camera_screen.dart';
import 'camera_pro_settings_sheet.dart';

/// O‘ng tomondagi vertikal «shisha» panel — mockup: PRO, chiroq, masshtab, yopish.
class CameraSideControls extends StatelessWidget {
  final CameraMode cameraMode;
  final bool showScale;
  final bool highSensitivityHorizon;
  final bool expertMode;
  final bool showHud;
  final FlashMode flashMode;
  final double zoom;
  final bool isDark;
  final Color glassColor;
  final Color glassBorder;
  final Color textColor;
  final Function(bool) onShowScaleChanged;
  final Function(bool) onHighSenseChanged;
  final Function(bool) onExpertModeChanged;
  final Function(bool) onHudToggle;
  final Function(FlashMode) onFlashModeChanged;
  final Function(double) onZoomChanged;
  final GlobalKey sensorLockButtonKey;
  final GlobalKey menuButtonKey;

  const CameraSideControls({
    super.key,
    required this.cameraMode,
    required this.showScale,
    required this.highSensitivityHorizon,
    required this.expertMode,
    required this.showHud,
    required this.flashMode,
    required this.zoom,
    required this.isDark,
    required this.glassColor,
    required this.glassBorder,
    required this.textColor,
    required this.onShowScaleChanged,
    required this.onHighSenseChanged,
    required this.onExpertModeChanged,
    required this.onHudToggle,
    required this.onFlashModeChanged,
    required this.onZoomChanged,
    required this.sensorLockButtonKey,
    required this.menuButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final showPro = cameraMode == CameraMode.geological;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPro) ...[
                _sideBtn(
                  key: menuButtonKey,
                  icon: Icons.workspace_premium_rounded,
                  label: context.locRead('camera_pro_short_label'),
                  tooltip: context.locRead('map_pro_tools_title'),
                  semanticLabel: context.locRead('map_pro_tools_title'),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (ctx) => CameraProSettingsSheet(
                        showScale: showScale,
                        highSensitivityHorizon: highSensitivityHorizon,
                        expertMode: expertMode,
                        showHud: showHud,
                        onShowScaleChanged: onShowScaleChanged,
                        onHighSenseChanged: onHighSenseChanged,
                        onExpertModeChanged: onExpertModeChanged,
                        onHudToggle: onHudToggle,
                        textColor: textColor,
                        sensorLockButtonKey: sensorLockButtonKey,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              _sideBtn(
                icon: flashMode == FlashMode.off ? Icons.flashlight_off_outlined : Icons.flashlight_on_outlined,
                label: context.loc('camera_torch_label'),
                active: flashMode != FlashMode.off,
                onTap: () {
                  final next = flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
                  onFlashModeChanged(next);
                },
              ),
              const SizedBox(height: 12),
              _sideBtn(
                icon: Icons.zoom_in_rounded,
                label: context.loc('camera_scale_label'),
                onTap: () => onZoomChanged((zoom + 0.5).clamp(1.0, 8.0)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${zoom.toStringAsFixed(1)}×',
                  style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              _sideBtn(
                icon: Icons.close_rounded,
                label: context.loc('camera_close_label'),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final didPop = await nav.maybePop();
                  if (!didPop && context.mounted) {
                    nav.pushReplacementNamed(AppRouter.dashboard);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideBtn({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    String? tooltip,
    String? semanticLabel,
  }) {
    Widget child = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: key,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1976D2) : glassColor,
              shape: BoxShape.circle,
              border: Border.all(color: glassBorder),
            ),
            child: Icon(icon, color: active ? Colors.white : textColor, size: 22),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.05,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
    if (semanticLabel != null) {
      child = Semantics(label: semanticLabel, button: true, child: child);
    }
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}
