import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Stitch mockup’dagi qorong‘i tekstura / iridescent fon — gradient bilan yaqinlashtirilgan.
class StitchScreenBackground extends StatelessWidget {
  const StitchScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkScaffold,
                  const Color(0xFF101820),
                  AppTheme.stitchBlueDeep.withValues(alpha: 0.35),
                  const Color(0xFF0A0E14),
                ],
                stops: const [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),
          CustomPaint(painter: _VeinPainter(), size: Size.infinite),
        ],
      ),
    );
  }
}

class _VeinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final c = Color.lerp(
        Colors.tealAccent,
        Colors.deepPurpleAccent,
        rnd.nextDouble(),
      )!
          .withValues(alpha: 0.04 + rnd.nextDouble() * 0.06);
      final p = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + (rnd.nextDouble() - 0.5) * 120,
          y + rnd.nextDouble() * 180,
          x + (rnd.nextDouble() - 0.5) * 80,
          y + 40 + rnd.nextDouble() * 100,
        );
      canvas.drawPath(
        p,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 + rnd.nextDouble() * 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
