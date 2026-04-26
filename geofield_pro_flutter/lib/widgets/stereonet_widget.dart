import 'package:flutter/material.dart';
import '../utils/geology_utils.dart';

class StereonetWidget extends StatelessWidget {
  final List<Map<String, double>> measurements; // List of {'strike': 0.0, 'dip': 0.0}
  final bool showPoles;
  final bool showGreatCircles;

  const StereonetWidget({
    super.key,
    required this.measurements,
    this.showPoles = true,
    this.showGreatCircles = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _StereonetWidgetPainter(
          measurements: measurements,
          showPoles: showPoles,
          showGreatCircles: showGreatCircles,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _StereonetWidgetPainter extends CustomPainter {
  final List<Map<String, double>> measurements;
  final bool showPoles;
  final bool showGreatCircles;
  final bool isDark;

  const _StereonetWidgetPainter({
    required this.measurements,
    required this.showPoles,
    required this.showGreatCircles,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;

    final bgPaint = Paint()
      ..color = isDark ? Colors.black26 : Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Qo'shimcha konsentrik doiralar (ring grid)
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 4, gridPaint);
    }

    // N-S, E-W asosiy chiziqlar
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), gridPaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), gridPaint);

    // N, E, S, W yorliqlari
    const textStyle = TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey);
    _drawText(canvas, 'N', Offset(center.dx, center.dy - radius - 15), textStyle);
    _drawText(canvas, 'S', Offset(center.dx, center.dy + radius + 5), textStyle);
    _drawText(canvas, 'E', Offset(center.dx + radius + 10, center.dy - 5), textStyle);
    _drawText(canvas, 'W', Offset(center.dx - radius - 20, center.dy - 5), textStyle);

    final polePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final circlePaint = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var m in measurements) {
      final strike = m['strike'] ?? 0.0;
      final dip = m['dip'] ?? 0.0;
      final dipDirection = (strike + 90) % 360;

      // Great Circle — StereonetEngine (geology_utils.dart) dan
      if (showGreatCircles) {
        final gcPoints = StereonetEngine.calculateGreatCircle(
          strike: strike,
          dip: dip,
          radius: 1.0, // Normalized [0..1]
          proj: StereonetProjection.schmidt,
        );
        if (gcPoints.isNotEmpty) {
          final path = Path();
          path.moveTo(
            center.dx + gcPoints[0].dx * radius,
            center.dy + gcPoints[0].dy * radius,
          );
          for (var p in gcPoints) {
            path.lineTo(
              center.dx + p.dx * radius,
              center.dy + p.dy * radius,
            );
          }
          canvas.drawPath(path, circlePaint);
        }
      }

      // Pole — StereonetEngine dan
      if (showPoles) {
        final projPoint = StereonetEngine.projectPole(
          dipDirection: dipDirection,
          dip: dip,
          radius: 1.0, // Normalized [0..1]
          proj: StereonetProjection.schmidt,
        );
        canvas.drawCircle(
          Offset(
            center.dx + projPoint.x * radius,
            center.dy + projPoint.y * radius,
          ),
          3.5,
          polePaint,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_StereonetWidgetPainter old) =>
      old.measurements != measurements ||
      old.showPoles != showPoles ||
      old.showGreatCircles != showGreatCircles ||
      old.isDark != isDark;
}
