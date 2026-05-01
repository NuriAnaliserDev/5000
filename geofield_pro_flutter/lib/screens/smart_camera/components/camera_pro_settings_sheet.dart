import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../utils/app_localizations.dart';

/// Kamera: o‘lchov chizgisi, H-Sense, expert, HUD — pastki varaq.
class CameraProSettingsSheet extends StatelessWidget {
  const CameraProSettingsSheet({
    super.key,
    required this.showScale,
    required this.highSensitivityHorizon,
    required this.expertMode,
    required this.showHud,
    required this.geologicalArEnabled,
    required this.showGeologicalArOption,
    required this.onShowScaleChanged,
    required this.onHighSenseChanged,
    required this.onExpertModeChanged,
    required this.onHudToggle,
    required this.onGeologicalArChanged,
    required this.textColor,
    this.sensorLockButtonKey,
  });

  final bool showScale;
  final bool highSensitivityHorizon;
  final bool expertMode;
  final bool showHud;
  final bool geologicalArEnabled;
  final bool showGeologicalArOption;
  final ValueChanged<bool> onShowScaleChanged;
  final ValueChanged<bool> onHighSenseChanged;
  final ValueChanged<bool> onExpertModeChanged;
  final ValueChanged<bool> onHudToggle;
  final ValueChanged<bool> onGeologicalArChanged;
  final Color textColor;
  final GlobalKey? sensorLockButtonKey;

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.map_pro_tools_title,
            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            s.camera_pro_sheet_hint,
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: showScale,
            onChanged: onShowScaleChanged,
            title: Text(
              context.locRead('ruler_label'),
              style: _tileStyle(textColor),
            ),
            secondary: Icon(Icons.straighten, color: textColor),
          ),
          SwitchListTile.adaptive(
            key: sensorLockButtonKey,
            value: highSensitivityHorizon,
            onChanged: onHighSenseChanged,
            title: Text('H-SENSE', style: _tileStyle(textColor)),
            secondary: Icon(Icons.speed, color: textColor),
          ),
          SwitchListTile.adaptive(
            value: expertMode,
            onChanged: onExpertModeChanged,
            title: Text(s.expert_mode, style: _tileStyle(textColor)),
            secondary: Icon(
              expertMode ? Icons.psychology : Icons.person_outline,
              color: textColor,
            ),
          ),
          SwitchListTile.adaptive(
            value: showHud,
            onChanged: onHudToggle,
            title: Text(
              context.locRead('hud_toggle'),
              style: _tileStyle(textColor),
            ),
            secondary: Icon(
              showHud ? Icons.visibility : Icons.visibility_off,
              color: textColor,
            ),
          ),
          if (showGeologicalArOption) ...[
            SwitchListTile.adaptive(
              value: geologicalArEnabled,
              onChanged: onGeologicalArChanged,
              title: Text(
                context.locRead('camera_ar_geology_title'),
                style: _tileStyle(textColor),
              ),
              subtitle: Text(
                context.locRead('camera_ar_geology_subtitle'),
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
              secondary: Icon(Icons.view_in_ar, color: textColor),
            ),
          ],
        ],
      ),
    );
  }

  static TextStyle _tileStyle(Color c) =>
      TextStyle(color: c, fontWeight: FontWeight.w600);
}
