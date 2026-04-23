import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_card.dart';
import '../smart_camera_screen.dart';

class CameraSideControls extends StatelessWidget {
  final Animation<double> menuAnimation;
  final AnimationController menuController;
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
    required this.menuAnimation,
    required this.menuController,
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
    final screenH = MediaQuery.of(context).size.height;
    final maxMenuHeight = (screenH - 320).clamp(220.0, 520.0).toDouble();
    final showAdvancedButtons = cameraMode == CameraMode.geological;

    return Positioned(
      right: 12, top: 170,
      child: AnimatedBuilder(
        animation: menuAnimation,
        builder: (context, child) {
          return AppCard(
            width: 70, opacity: 0.35, blur: 15, borderRadius: 35, padding: const EdgeInsets.symmetric(vertical: 20),
            baseColor: isDark ? Colors.black : Colors.white, border: Border.all(color: glassBorder, width: 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (menuAnimation.value > 0.01)
                  FadeTransition(
                    opacity: menuAnimation,
                    child: SizeTransition(
                      sizeFactor: menuAnimation,
                      child: SizedBox(
                        height: maxMenuHeight,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (showAdvancedButtons) ...[
                                _sideBtn(
                                  icon: Icons.straighten,
                                  label: context.locRead('ruler_label'),
                                  active: showScale,
                                  onTap: () => onShowScaleChanged(!showScale),
                                ),
                                const SizedBox(height: 10),
                                _sideBtn(
                                  icon: Icons.speed,
                                  label: 'H-SENSE',
                                  active: highSensitivityHorizon,
                                  onTap: () => onHighSenseChanged(!highSensitivityHorizon),
                                ),
                                SizedBox(height: 10, key: sensorLockButtonKey),
                                const SizedBox(height: 10),
                                _sideBtn(
                                  icon: expertMode ? Icons.psychology : Icons.person_outline,
                                  label: expertMode ? 'EXPERT' : 'BASIC',
                                  active: expertMode,
                                  onTap: () => onExpertModeChanged(!expertMode),
                                ),
                                const SizedBox(height: 10),
                                _sideBtn(
                                  icon: showHud ? Icons.visibility : Icons.visibility_off,
                                  label: context.locRead('hud_toggle').toUpperCase(),
                                  active: showHud,
                                  onTap: () => onHudToggle(!showHud),
                                ),
                                const SizedBox(height: 10),
                              ],
                              _sideBtn(
                                icon: flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                                label: context.locRead('light_toggle').toUpperCase(),
                                active: flashMode != FlashMode.off,
                                onTap: () {
                                  FlashMode next = flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
                                  onFlashModeChanged(next);
                                },
                              ),
                              const SizedBox(height: 10),
                              _sideBtn(
                                icon: Icons.add,
                                label: '${context.locRead('zoom_label').toUpperCase()} +',
                                onTap: () => onZoomChanged((zoom + 0.5).clamp(1.0, 8.0)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('${zoom.toStringAsFixed(1)}x', style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              _sideBtn(
                                icon: Icons.remove,
                                label: '${context.locRead('zoom_label').toUpperCase()} -',
                                onTap: () => onZoomChanged((zoom - 0.5).clamp(1.0, 8.0)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    if (menuController.isCompleted) {
                      menuController.reverse();
                    } else {
                      menuController.forward();
                    }
                  },
                  child: Transform.rotate(
                    angle: menuAnimation.value * 0.5 * 3.14159,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: menuController.isAnimating || menuController.isCompleted
                            ? const Color(0xFF1976D2)
                            : Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      ),
                      child: Icon(
                        key: menuButtonKey,
                        menuAnimation.value > 0.5 ? Icons.close : Icons.settings,
                        color: menuAnimation.value > 0.5 ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sideBtn({required IconData icon, required String label, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: active ? const Color(0xFF1976D2) : glassColor, shape: BoxShape.circle, border: Border.all(color: glassBorder)),
            child: Icon(icon, color: active ? Colors.white : textColor, size: 22),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
