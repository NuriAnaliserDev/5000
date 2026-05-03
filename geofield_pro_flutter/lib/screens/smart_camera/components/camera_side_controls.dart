import 'dart:math' as math;

import 'package:camera/camera.dart' show FlashMode;
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

import '../../../app/app_theme.dart';
import '../../../app/main_tab_navigation.dart';
import '../../../utils/app_localizations.dart';
import '../smart_camera_screen.dart';
import 'camera_pro_settings_sheet.dart';

/// O‘ng tomonda bitta tugma; bosilganda Pro / chiroq / masshtab / yopish yoyiladi.
class CameraSideControls extends StatefulWidget {
  final CameraMode cameraMode;
  final bool showScale;
  final bool highSensitivityHorizon;
  final bool expertMode;
  final bool showHud;
  final bool geologicalArEnabled;
  final bool showGeologicalArOption;
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
  final Function(bool) onGeologicalArChanged;
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
    required this.geologicalArEnabled,
    required this.showGeologicalArOption,
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
    required this.onGeologicalArChanged,
    required this.onFlashModeChanged,
    required this.onZoomChanged,
    required this.sensorLockButtonKey,
    required this.menuButtonKey,
  });

  @override
  State<CameraSideControls> createState() => _CameraSideControlsState();
}

class _CamDialItem {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Key? itemKey;

  const _CamDialItem({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.itemKey,
  });
}

class _CameraSideControlsState extends State<CameraSideControls>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _setOpen(bool v) {
    setState(() => _open = v);
    if (v) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _toggle() {
    _setOpen(!_open);
  }

  void _run(VoidCallback fn) {
    _setOpen(false);
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (mounted) {
        fn();
      }
    });
  }

  Widget _miniSatellite(_CamDialItem item, int i, int n, double t) {
    final progress = t.clamp(0.0, 1.0);
    final u = n <= 1 ? 0.5 : i / (n - 1);
    final angle = math.pi * (0.97 - u * 0.48);
    const double r = 92;
    final dx = math.cos(angle) * r * progress;
    final dy = math.sin(angle) * r * progress;
    const double fabR = 29;
    return Positioned(
      right: fabR - dx,
      bottom: fabR + dy,
      child: IgnorePointer(
        ignoring: progress < 0.1,
        child: Opacity(
          opacity: progress,
          child: Transform.scale(
            key: item.itemKey,
            scale: 0.5 + 0.5 * progress,
            alignment: Alignment.center,
            child: Tooltip(
              message: item.tooltip,
              child: Material(
                color: item.active ? AppTheme.stitchBlue : widget.glassColor,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _run(item.onTap),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      item.icon,
                      color: item.active ? Colors.white : widget.textColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPro = widget.cameraMode == CameraMode.geological;
    final items = <_CamDialItem>[
      if (showPro)
        _CamDialItem(
          tooltip: context.locRead('map_pro_tools_title'),
          icon: Icons.workspace_premium_rounded,
          itemKey: widget.menuButtonKey,
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (ctx) => CameraProSettingsSheet(
                showScale: widget.showScale,
                highSensitivityHorizon: widget.highSensitivityHorizon,
                expertMode: widget.expertMode,
                showHud: widget.showHud,
                geologicalArEnabled: widget.geologicalArEnabled,
                showGeologicalArOption: widget.showGeologicalArOption,
                onShowScaleChanged: widget.onShowScaleChanged,
                onHighSenseChanged: widget.onHighSenseChanged,
                onExpertModeChanged: widget.onExpertModeChanged,
                onHudToggle: widget.onHudToggle,
                onGeologicalArChanged: widget.onGeologicalArChanged,
                textColor: widget.textColor,
                sensorLockButtonKey: widget.sensorLockButtonKey,
              ),
            );
          },
        ),
      _CamDialItem(
        tooltip: context.loc('camera_torch_label'),
        icon: widget.flashMode == FlashMode.off
            ? Icons.flashlight_off_outlined
            : Icons.flashlight_on_outlined,
        active: widget.flashMode != FlashMode.off,
        onTap: () {
          final next = widget.flashMode == FlashMode.off
              ? FlashMode.torch
              : FlashMode.off;
          widget.onFlashModeChanged(next);
        },
      ),
      _CamDialItem(
        tooltip:
            '${context.loc('camera_scale_label')} (${widget.zoom.toStringAsFixed(1)}×)',
        icon: Icons.zoom_in_rounded,
        onTap: () => widget.onZoomChanged((widget.zoom + 0.5).clamp(1.0, 8.0)),
      ),
      _CamDialItem(
        tooltip: context.loc('camera_close_label'),
        icon: Icons.close_rounded,
        onTap: () {
          _setOpen(false);
          final nav = Navigator.of(context);
          Future<void>.delayed(const Duration(milliseconds: 70), () async {
            if (!mounted) {
              return;
            }
            final didPop = await nav.maybePop();
            if (!mounted) return;
            if (!didPop && context.mounted) {
              MainTabNavigation.openDashboard(context);
            }
          });
        },
      ),
    ];

    return SizedBox(
      width: 210,
      height: 268,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final t = _curve.value.clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < items.length; i++)
                    if (t >= 0.03) _miniSatellite(items[i], i, items.length, t),
                ],
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggle,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(
                        _open ? Icons.close_rounded : Icons.tune_rounded,
                        color: widget.textColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
