import 'dart:math' as math;
import 'package:flutter/material.dart';

enum GeologicalSym {
  beddingInclined,
  beddingVertical,
  beddingHorizontal,
  foliationInclined,
  foliationVertical,
  jointInclined,
  jointVertical,
  cleavageInclined,
  faultInclined,
  lineation
}

class GeologicalSymbolPainter extends CustomPainter {
  final GeologicalSym type;
  final Color color;
  final double dip; // degrees

  GeologicalSymbolPainter({
    required this.type,
    this.color = Colors.black,
    this.dip = 45,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    switch (type) {
      case GeologicalSym.beddingInclined:
        // Long strike line
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // Short dip tick (at center, pointing 'down' which is 90 deg from strike)
        canvas.drawLine(center, Offset(center.dx, center.dy + r * 0.5), paint);
        break;

      case GeologicalSym.beddingVertical:
        // Long strike line
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // Ticks on both sides
        canvas.drawLine(center, Offset(center.dx, center.dy + r * 0.4), paint);
        canvas.drawLine(center, Offset(center.dx, center.dy - r * 0.4), paint);
        break;

      case GeologicalSym.beddingHorizontal:
        // Cross inside a circle (simplified)
        canvas.drawCircle(center, r * 0.3, paint);
        canvas.drawLine(Offset(center.dx - r * 0.6, center.dy), Offset(center.dx + r * 0.6, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - r * 0.6), Offset(center.dx, center.dy + r * 0.6), paint);
        break;

      case GeologicalSym.foliationInclined:
        // Long strike line
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // Triple dip ticks
        canvas.drawLine(Offset(center.dx - r * 0.3, center.dy), Offset(center.dx - r * 0.3, center.dy + r * 0.4), paint);
        canvas.drawLine(center, Offset(center.dx, center.dy + r * 0.4), paint);
        canvas.drawLine(Offset(center.dx + r * 0.3, center.dy), Offset(center.dx + r * 0.3, center.dy + r * 0.4), paint);
        break;

      case GeologicalSym.jointInclined:
        // Long strike line
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // No dip tick or a very small centered circle
        canvas.drawCircle(center, 2, paint..style = PaintingStyle.fill);
        break;

      case GeologicalSym.cleavageInclined:
        // Long strike line
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // Multiple small ticks on one side
        for (var i = -2; i <= 2; i++) {
          final x = center.dx + (i * r * 0.3);
          canvas.drawLine(Offset(x, center.dy), Offset(x, center.dy + r * 0.3), paint);
        }
        break;
      
      case GeologicalSym.faultInclined:
        // Thick strike line
        paint.strokeWidth = 4.0;
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), paint);
        // Dip arrow
        paint.strokeWidth = 2.0;
        canvas.drawLine(center, Offset(center.dx, center.dy + r * 0.6), paint);
        break;

      case GeologicalSym.lineation:
        // Arrow pointing in trend direction
        canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), paint);
        canvas.drawLine(Offset(center.dx, center.dy + r), Offset(center.dx - r * 0.3, center.dy + r * 0.5), paint);
        canvas.drawLine(Offset(center.dx, center.dy + r), Offset(center.dx + r * 0.3, center.dy + r * 0.5), paint);
        break;

      default:
        canvas.drawCircle(center, 4, paint..style = PaintingStyle.fill);
    }
    
    // Dip Value Typography (Optional - showing dip number next to symbol)
    if (dip > 0 && type != GeologicalSym.beddingHorizontal && type != GeologicalSym.beddingVertical) {
       // We can add text here if needed, but usually kept simple for map
    }
  }

  @override
  bool shouldRepaint(covariant GeologicalSymbolPainter oldDelegate) => 
    oldDelegate.type != type || oldDelegate.color != color || oldDelegate.dip != dip;
}

class GeologicalSymbolWidget extends StatelessWidget {
  final String measurementType;
  final String subType;
  final double dip;
  final double strike;
  final double size;
  final Color color;

  const GeologicalSymbolWidget({
    super.key,
    required this.measurementType,
    this.subType = 'inclined',
    required this.dip,
    required this.strike,
    this.size = 30,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    GeologicalSym sym;
    
    // Map string types to enum
    switch (measurementType.toLowerCase()) {
      case 'bedding':
        if (dip > 85 || subType == 'vertical') {
          sym = GeologicalSym.beddingVertical;
        } else if (dip < 5 || subType == 'horizontal') {
          sym = GeologicalSym.beddingHorizontal;
        } else {
          sym = GeologicalSym.beddingInclined;
        }
        break;
      case 'foliation':
        sym = GeologicalSym.foliationInclined;
        break;
      case 'cleavage':
        sym = GeologicalSym.cleavageInclined;
        break;
      case 'joint':
        sym = GeologicalSym.jointInclined;
        break;
      case 'fault':
        sym = GeologicalSym.faultInclined;
        break;
      case 'lineation':
        sym = GeologicalSym.lineation;
        break;
      default:
        sym = GeologicalSym.beddingInclined;
    }

    return Transform.rotate(
      angle: strike * math.pi / 180,
      child: CustomPaint(
        size: Size(size, size),
        painter: GeologicalSymbolPainter(
          type: sym,
          color: color,
          dip: dip,
        ),
      ),
    );
  }
}
