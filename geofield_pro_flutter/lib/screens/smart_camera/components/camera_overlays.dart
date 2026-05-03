import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

class CameraCalibrationOverlay extends StatelessWidget {
  final VoidCallback onConfirm;

  const CameraCalibrationOverlay({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.5),
                  width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.screen_rotation,
                    size: 48, color: Color(0xFF1976D2)),
                const SizedBox(height: 16),
                Text(context.loc('compass_calibration'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(context.loc('compass_calibration_long'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14, height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onConfirm,
                    child: Text(context.loc('confirm'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CameraRulerOverlay extends StatelessWidget {
  const CameraRulerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final pixelsPerMm = context.watch<SettingsController>().pixelsPerMm;
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 100,
      child: IgnorePointer(
        child: CustomPaint(
          painter: RulerOverlayPainter(pixelsPerMm: pixelsPerMm),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class RulerOverlayPainter extends CustomPainter {
  final double pixelsPerMm;
  RulerOverlayPainter({required this.pixelsPerMm});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 2;
    final textStyle = const TextStyle(
        color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w900);
    double startY = size.height;
    int mm = 0;
    while (startY >= 0) {
      double length = 15;
      if (mm % 10 == 0) {
        length = 40;
        final tp = TextPainter(
            text: TextSpan(text: '${mm ~/ 10}', style: textStyle),
            textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(length + 4, startY - tp.height / 2));
      } else if (mm % 5 == 0) {
        length = 25;
      }
      canvas.drawLine(Offset(0, startY), Offset(length, startY), paint);
      startY -= pixelsPerMm;
      mm += 1;
    }
  }

  @override
  bool shouldRepaint(RulerOverlayPainter oldDelegate) =>
      oldDelegate.pixelsPerMm != pixelsPerMm;
}

class CameraDocumentViewfinder extends StatelessWidget {
  const CameraDocumentViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.width * 0.85 * 1.41, // A4 ratio
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFF1976D2).withValues(alpha: 0.6),
                width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              _corner(Alignment.topLeft),
              _corner(Alignment.topRight),
              _corner(Alignment.bottomLeft),
              _corner(Alignment.bottomRight),
              const ScannerLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            right: (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class ScannerLine extends StatefulWidget {
  const ScannerLine({super.key});

  @override
  State<ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<ScannerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Align(
          alignment: Alignment(0, _ctrl.value * 2 - 1),
          child: Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.greenAccent.withValues(alpha: 0.8),
                  Colors.transparent
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
