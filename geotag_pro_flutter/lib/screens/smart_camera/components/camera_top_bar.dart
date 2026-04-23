import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/location_service.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_card.dart';
import '../smart_camera_screen.dart';

class CameraTopBar extends StatelessWidget {
  final CameraMode cameraMode;
  final Function(CameraMode) onModeChanged;
  final bool isDark;
  final Color glassBorder;
  final Color textColor;
  final Color subTextColor;

  const CameraTopBar({
    super.key,
    required this.cameraMode,
    required this.onModeChanged,
    required this.isDark,
    required this.glassBorder,
    required this.textColor,
    required this.subTextColor,
    required GlobalKey modeToggleKey,
  }) : _modeToggleKey = modeToggleKey;

  final GlobalKey _modeToggleKey;

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final pos = locService.currentPosition;
    final isCompact = MediaQuery.of(context).size.width < 390;

    return Positioned(
      top: 10, left: 10, right: 10,
      child: AppCard(
        baseColor: isDark ? Colors.black : Colors.white,
        opacity: 0.4, blur: 12, borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: Border.all(color: glassBorder, width: 0.5),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            // MODE TOGGLE
            Expanded(
              child: Container(
                key: _modeToggleKey,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: _modeTab(context, CameraMode.geological, Icons.landscape, context.loc('camera_mode_geology'))),
                    Expanded(child: _modeTab(context, CameraMode.document, Icons.description, context.loc('camera_mode_document'))),
                  ],
                ),
              ),
            ),
            if (!isCompact)
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cameraMode == CameraMode.geological
                          ? context.loc('camera_header_geology')
                          : context.loc('camera_header_document'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 10, color: subTextColor.withValues(alpha: 0.6)),
                    ),
                    Text(
                      pos != null
                          ? '${pos.latitude.toStringAsFixed(5)}°, ${pos.longitude.toStringAsFixed(5)}°'
                          : context.loc('signal_searching'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(BuildContext context, CameraMode mode, IconData icon, String label) {
    bool selected = cameraMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
