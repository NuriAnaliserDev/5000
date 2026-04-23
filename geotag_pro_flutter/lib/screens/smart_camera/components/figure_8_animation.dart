import 'package:flutter/material.dart';

class Figure8Animation extends StatefulWidget {
  const Figure8Animation({super.key});

  @override
  State<Figure8Animation> createState() => _Figure8AnimationState();
}

class _Figure8AnimationState extends State<Figure8Animation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
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
      builder: (context, _) => CustomPaint(size: const Size(100, 60), painter: _Figure8Painter(_ctrl.value)),
    );
  }
}

class _Figure8Painter extends CustomPainter {
  final double progress;
  _Figure8Painter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    path.moveTo(size.width / 2, size.height / 2);
    path.cubicTo(size.width * 0.8, size.height * 0.1, size.width * 1.1, size.height * 0.9, size.width / 2, size.height / 2);
    path.cubicTo(size.width * 0.2, size.height * 0.1, -size.width * 0.1, size.height * 0.9, size.width / 2, size.height / 2);
    canvas.drawPath(path, p);
    final metric = path.computeMetrics().first;
    final pos = metric.getTangentForOffset(metric.length * progress)?.position;
    if (pos != null) canvas.drawCircle(pos, 4, Paint()..color = const Color(0xFF1976D2));
  }

  @override
  bool shouldRepaint(_Figure8Painter old) => old.progress != progress;
}
