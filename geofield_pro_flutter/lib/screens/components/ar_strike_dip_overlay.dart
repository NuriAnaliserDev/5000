import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import '../../utils/geology_utils.dart';

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

  static String _bearing8(double deg) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((deg + 22.5) / 45).floor() % 8;
    return labels[i];
  }

  @override
  Widget build(BuildContext context) {
    final bool isLevel = pitch.abs() < 2.0 && roll.abs() < 2.0;
    final color = isLevel ? Colors.greenAccent : (isDark ? Colors.white : Colors.black);
    final dipDir = _bearing8(GeologyUtils.calculateDipDirection(strike));

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // AR «instrument» yuqori-markazda — past markaz ko‘rinish uchun bo‘sh.
        const double instrumentY = 0.34;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EllipseRingsPainter(
                  roll: roll,
                  pitch: pitch,
                  centerYFactor: instrumentY,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _VirtualPlanePainter(
                  pitch: pitch,
                  roll: roll,
                  strike: strike,
                  dip: dip,
                  color: color,
                  centerYFactor: instrumentY,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * (instrumentY - 0.20),
              child: Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.redAccent.shade100,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * (instrumentY + 0.16),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: h * (instrumentY - 0.08),
              child: _StrikeDipCallout(
                text: '${context.locRead('strike_label')}: ${strike.toStringAsFixed(0)}°',
                borderColor: Colors.redAccent.withValues(alpha: 0.65),
              ),
            ),
            Positioned(
              right: 10,
              top: h * (instrumentY + 0.00),
              child: _StrikeDipCallout(
                text: '${context.locRead('dip_label')}: ${dip.toStringAsFixed(0)}° $dipDir',
                borderColor: const Color(0xFF64B5F6).withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: h * instrumentY - 18,
              height: 36,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 26, height: 1.2, color: Colors.white24),
                    Container(width: 1.2, height: 26, color: Colors.white24),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
                        color: isLevel ? color.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '${context.locRead('horizon_level')} ✓',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StrikeDipCallout extends StatelessWidget {
  final String text;
  final Color borderColor;

  const _StrikeDipCallout({
    required this.text,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _EllipseRingsPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final double centerYFactor;

  _EllipseRingsPainter({
    required this.roll,
    required this.pitch,
    this.centerYFactor = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(
      size.width / 2,
      size.height * centerYFactor + pitch * 2,
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-roll * math.pi / 180);
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 1; i <= 3; i++) {
      final rx = 26.0 + i * 26;
      final ry = 15.0 + i * 15;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EllipseRingsPainter oldDelegate) =>
      oldDelegate.roll != roll ||
      oldDelegate.pitch != pitch ||
      oldDelegate.centerYFactor != centerYFactor;
}

class _VirtualPlanePainter extends CustomPainter {
  final double pitch;
  final double roll;
  final double strike;
  final double dip;
  final Color color;
  final double centerYFactor;

  _VirtualPlanePainter({
    required this.pitch,
    required this.roll,
    required this.strike,
    required this.dip,
    required this.color,
    this.centerYFactor = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * centerYFactor);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll * math.pi / 180);
    canvas.translate(0, -pitch * 4.5);
    canvas.rotate(strike * math.pi / 180);

    final horizonPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-size.width, 0), Offset(size.width, 0), horizonPaint);

    _drawProjectedPlane(canvas, size);

    canvas.restore();
  }

  void _drawProjectedPlane(Canvas canvas, Size size) {
    final dipRad = dip * math.pi / 180;
    final double plateWidth = size.width * 0.42;
    final double plateHeight = size.height * 0.18;
    final double foreshorten = math.cos(dipRad).abs().clamp(0.2, 1.0);

    final Path planePath = Path();
    final double topW = plateWidth * foreshorten;
    final double topY = -plateHeight / 2 * math.sin(dipRad);
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
          Colors.red.withValues(alpha: 0.12),
          const Color(0xFF1976D2).withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromLTWH(-botW / 2, topY, botW, botY - topY))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(planePath, fillPaint);
    canvas.drawPath(planePath, borderPaint);

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (double i = -0.4; i <= 0.4; i += 0.2) {
      canvas.drawLine(
        Offset(topW * i, topY),
        Offset(botW * i, botY),
        gridPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${dip.toStringAsFixed(0)}°',
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, (topY + botY) / 2 - textPainter.height / 2),
    );

    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double arrowLen = 40.0;
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
      oldDelegate.color != color ||
      oldDelegate.centerYFactor != centerYFactor;
}
