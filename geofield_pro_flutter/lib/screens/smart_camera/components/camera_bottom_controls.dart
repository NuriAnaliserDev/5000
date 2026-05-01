import 'dart:math' as math;
import 'dart:ui';

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
    final s = GeoFieldStrings.of(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final voiceLabel = s?.camera_voice_record_label ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomSafe * 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Color(0xFFFF1744), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      formatDuration(recordSeconds),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (pos != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 8, bottom: 20),
                  child: StatusBadge(
                    label: '±${pos.accuracy.toStringAsFixed(1)}m',
                    level: pos.accuracy < 15 ? StatusLevel.good : StatusLevel.warn,
                    fontSize: 11,
                  ),
                )
              else
                const SizedBox(width: 6),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onCapture,
                    child: Container(
                      key: shutterButtonKey,
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: compassQuality < 40
                              ? Colors.redAccent.withValues(alpha: 0.65)
                              : const Color(0xFF212121),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBusy
                                ? Colors.grey.shade600
                                : (compassQuality < 40
                                    ? Colors.red.withValues(alpha: 0.35)
                                    : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.2),
                            child: InkWell(
                              onTap: onToggleRecording,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.35)),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isRecording
                                            ? const Color(0xFFFF1744)
                                            : Colors.white
                                                .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        isRecording
                                            ? Icons.stop_rounded
                                            : Icons
                                                .fiber_manual_record_outlined,
                                        color: isRecording
                                            ? Colors.white
                                            : Colors.black87,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        height: 32,
                                        child: CustomPaint(
                                          painter: _VoiceWavePainter(
                                              active: isRecording,
                                              tick: recordSeconds),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (voiceLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            voiceLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.92),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 3),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final bool active;
  final int tick;

  _VoiceWavePainter({required this.active, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: active ? 0.95 : 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final n = 28;
    final dw = size.width / n;
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      var h = 3.0;
      if (active) {
        h =
            5 + (size.height * 0.38) * (0.5 + 0.5 * math.sin(i * 0.55 + tick * 0.35));
      } else {
        h = 2 + math.sin(i * 0.45 + tick * 0.05) * 2;
      }
      final x = i * dw + dw / 2;
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter old) =>
      old.active != active || old.tick != tick;
}
