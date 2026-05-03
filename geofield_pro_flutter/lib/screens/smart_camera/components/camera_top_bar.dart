import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:provider/provider.dart';

import '../../../app/app_theme.dart';
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
  final bool allowDocumentMode;
  final GlobalKey modeToggleKey;

  const CameraTopBar({
    super.key,
    required this.cameraMode,
    required this.onModeChanged,
    required this.isDark,
    required this.glassBorder,
    required this.textColor,
    required this.subTextColor,
    this.allowDocumentMode = true,
    required this.modeToggleKey,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraMode == CameraMode.geological) {
      final pad = MediaQuery.paddingOf(context);
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.stitchBlueDeep.withValues(alpha: 0.58),
                border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: pad.top),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.stitchBlue.withValues(alpha: 0.95),
                            size: 20),
                        onPressed: () {
                          if (context.canPop()) context.pop();
                        },
                      ),
                      Expanded(
                        child: Text(
                          context.loc('camera_focus_mode_title'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (allowDocumentMode)
                        IconButton(
                          key: modeToggleKey,
                          icon: Icon(Icons.description_outlined,
                              color: Colors.white.withValues(alpha: 0.92),
                              size: 22),
                          tooltip: context.loc('camera_mode_document'),
                          onPressed: () => onModeChanged(CameraMode.document),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final locService = context.watch<LocationService>();
    final pos = locService.currentPosition;
    final isCompact = MediaQuery.of(context).size.width < 390;

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: AppCard(
        baseColor: isDark ? Colors.black : Colors.white,
        opacity: 0.4,
        blur: 12,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: Border.all(color: glassBorder, width: 0.5),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: allowDocumentMode
                  ? Container(
                      key: modeToggleKey,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _modeTab(
                              context,
                              CameraMode.geological,
                              Icons.landscape,
                              context.loc('camera_mode_geology'),
                            ),
                          ),
                          Expanded(
                            child: _modeTab(
                              context,
                              CameraMode.document,
                              Icons.description,
                              context.loc('camera_mode_document'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      key: modeToggleKey,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        context.loc('camera_mode_geology'),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 10,
                        color: subTextColor.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      pos != null
                          ? '${pos.latitude.toStringAsFixed(5)}°, ${pos.longitude.toStringAsFixed(5)}°'
                          : context.loc('signal_searching'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(
      BuildContext context, CameraMode mode, IconData icon, String label) {
    final selected = cameraMode == mode;
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
            Icon(icon,
                size: 14, color: selected ? Colors.white : Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
