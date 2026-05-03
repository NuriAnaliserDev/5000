import 'package:flutter/material.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

class ScaleDigitalRuler extends StatelessWidget {
  final SettingsController settings;

  const ScaleDigitalRuler({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12,
                  blurRadius: 10)
            ],
          ),
          child: CustomPaint(
            painter: _RulerPainter(
                pixelsPerMm: settings.pixelsPerMm, isDark: isDark),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.tune, color: Colors.grey, size: 14),
            const SizedBox(width: 8),
            Text(context.loc('ruler_calibration_title'),
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: settings.pixelsPerMm,
          min: 4.0,
          max: 12.0,
          activeColor: const Color(0xFF1976D2),
          onChanged: (v) => settings.pixelsPerMm = v,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1976D2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF1976D2), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFF1976D2), size: 18),
                        const SizedBox(width: 8),
                        Text(context.loc('mandatory_step_label'),
                            style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 12,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.loc('calibration_instruction'),
                      style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double pixelsPerMm;
  final bool isDark;
  _RulerPainter({required this.pixelsPerMm, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.black : Colors.black87
      ..strokeWidth = 1;

    // Ruler background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8)),
      Paint()..color = Colors.white,
    );

    for (double i = 0; i < size.width; i += pixelsPerMm) {
      double height = 10;
      final mm = (i / pixelsPerMm).round();

      if (mm % 10 == 0) {
        height = 35;
        final textPainter = TextPainter(
          text: TextSpan(
              text: '${mm ~/ 10}',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
            canvas, Offset(i - textPainter.width / 2, height + 4));
      } else if (mm % 5 == 0) {
        height = 20;
      }

      canvas.drawLine(Offset(i, 0), Offset(i, height), paint);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) =>
      oldDelegate.pixelsPerMm != pixelsPerMm;
}
