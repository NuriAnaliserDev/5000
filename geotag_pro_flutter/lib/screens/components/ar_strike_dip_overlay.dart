import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArStrikeDipOverlay extends StatelessWidget {
  final double pitch;
  final double roll;
  final double strike;
  final double dip;
  final bool isDark;

  const ArStrikeDipOverlay({
    super.key,
    required this.pitch,
    required this.roll,
    required this.strike,
    required this.dip,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLevel = pitch.abs() < 2.0 && roll.abs() < 2.0;
    final color = isLevel ? Colors.greenAccent : (isDark ? Colors.white : Colors.black);

    return Stack(
      children: [
        // 3D Projected Plane Layer
        Positioned.fill(
          child: CustomPaint(
            painter: _VirtualPlanePainter(
              pitch: pitch,
              roll: roll,
              strike: strike,
              dip: dip,
              color: color,
            ),
          ),
        ),

        // Central HUD UI
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Static crosshair
              Container(width: 30, height: 1.5, color: Colors.white24),
              Container(width: 1.5, height: 30, color: Colors.white24),

              // Level indicator bullseye
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                  color: isLevel ? color.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),

        // Status Banner
        if (isLevel)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'LEVEL ✓',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VirtualPlanePainter extends CustomPainter {
  final double pitch;
  final double roll;
  final double strike;
  final double dip;
  final Color color;

  _VirtualPlanePainter({
    required this.pitch,
    required this.roll,
    required this.strike,
    required this.dip,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. Initial rotation (device roll + geological strike)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // We rotate by -roll for device leveling, 
    // and then we should rotate the plane by the 'strike' relative to North.
    // However, AR overlays usually combine device compass (azimuth) and strike.
    // Here we just apply the roll first.
    canvas.rotate(-roll * math.pi / 180);
    
    // 2. Vertical shift (device pitch)
    canvas.translate(0, -pitch * 6.0);
    
    // 2.5. Apply Strike Rotation on the virtual plane itself
    // Assuming 0 strike is "forward" in this view context
    canvas.rotate(strike * math.pi / 180);
    
    // 3. Draw Horizon Line (Reference)
    final horizonPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-size.width, 0), Offset(size.width, 0), horizonPaint);

    // 4. Draw Structural Plane (3D-ish projection)
    _drawProjectedPlane(canvas, size);

    canvas.restore();
  }

  void _drawProjectedPlane(Canvas canvas, Size size) {
    // The "Geological Plane" is defined relative to the flat horizontal device.
    // We simulate a 3D perspective by drawing a trapezoid.
    
    final dipRad = dip * math.pi / 180;
    
    // Width of the virtual plane plate
    final double plateWidth = size.width * 0.8;
    final double plateHeight = size.height * 0.4;

    // Perspective factor: further side is narrower
    // When dip is high, the "foreshortening" is high
    final double foreshorten = math.cos(dipRad).abs().clamp(0.2, 1.0);
    
    final Path planePath = Path();
    
    // Top corners (further away)
    final double topW = plateWidth * foreshorten;
    final double topY = -plateHeight / 2 * math.sin(dipRad);
    
    // Bottom corners (closer)
    final double botW = plateWidth;
    final double botY = plateHeight / 2 * math.sin(dipRad);

    planePath.moveTo(-topW / 2, topY);
    planePath.lineTo(topW / 2, topY);
    planePath.lineTo(botW / 2, botY);
    planePath.lineTo(-botW / 2, botY);
    planePath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(-botW/2, topY, botW, botY - topY))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(planePath, fillPaint);
    canvas.drawPath(planePath, borderPaint);

    // Draw Grid Lines on the plane
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    // Vertical grid (Dip direction)
    for (double i = -0.4; i <= 0.4; i += 0.2) {
      canvas.drawLine(
        Offset(topW * i, topY),
        Offset(botW * i, botY),
        gridPaint
      );
    }
    
    // 5. Draw Dip Value Text and Arrow
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${dip.toStringAsFixed(0)}°',
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Center text on the plane
    textPainter.paint(canvas, Offset(-textPainter.width / 2, (topY + botY) / 2 - textPainter.height / 2));

    // Dip Direction Arrow
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double arrowLen = 40.0;
    final double arrowBaseY = botY - 10;
    canvas.drawLine(Offset(0, arrowBaseY - arrowLen), Offset(0, arrowBaseY), arrowPaint);
    canvas.drawLine(Offset(-8, arrowBaseY - 8), Offset(0, arrowBaseY), arrowPaint);
    canvas.drawLine(Offset(8, arrowBaseY - 8), Offset(0, arrowBaseY), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _VirtualPlanePainter oldDelegate) => 
    oldDelegate.pitch != pitch || 
    oldDelegate.roll != roll || 
    oldDelegate.dip != dip || 
    oldDelegate.strike != strike ||
    oldDelegate.color != color;
}
