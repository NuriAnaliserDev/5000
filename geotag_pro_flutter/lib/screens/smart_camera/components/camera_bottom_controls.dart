import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/location_service.dart';
import '../../../utils/status_semantics.dart';
import '../../../widgets/common/status_badge.dart';

class CameraBottomControls extends StatelessWidget {
  final bool isRecording;
  final int recordSeconds;
  final bool isBusy;
  final int compassQuality;
  final bool isDark;
  final Color glassColor;
  final Color textColor;
  final VoidCallback onToggleRecording;
  final VoidCallback onCapture;
  final String Function(int) formatDuration;
  final GlobalKey shutterButtonKey;

  const CameraBottomControls({
    super.key,
    required this.isRecording,
    required this.recordSeconds,
    required this.isBusy,
    required this.compassQuality,
    required this.isDark,
    required this.glassColor,
    required this.textColor,
    required this.onToggleRecording,
    required this.onCapture,
    required this.formatDuration,
    required this.shutterButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<LocationService>().currentPosition;
    final voiceHint = GeoFieldStrings.of(context)?.camera_voice_mic_hint ?? '';
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voiceHint.isNotEmpty && !isRecording)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                voiceHint,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_manual_record, color: Color(0xFFFF1744), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    formatDuration(recordSeconds),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: voiceHint,
                child: IconButton(
                  iconSize: 32,
                  color: isRecording ? const Color(0xFFFF1744) : (isDark ? Colors.white : Colors.black),
                  icon: Icon(isRecording ? Icons.mic : Icons.mic_none),
                  onPressed: onToggleRecording,
                ),
              ),
              const SizedBox(width: 40),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pos != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StatusBadge(
                        label: '±${pos.accuracy.toStringAsFixed(1)}m',
                        level: pos.accuracy < 15 ? StatusLevel.good : StatusLevel.warn,
                        fontSize: 11,
                      ),
                    ),
                  GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      key: shutterButtonKey,
                      width: 80, height: 80, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: compassQuality < 40 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), width: 4)
                      ), 
                      child: Center(
                        child: Container(
                          width: 64, height: 64, 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBusy ? Colors.grey : (compassQuality < 40 ? Colors.red.withValues(alpha: 0.3) : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              IconButton(
                iconSize: 30,
                color: const Color(0xFF1976D2),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      );
  }
}
