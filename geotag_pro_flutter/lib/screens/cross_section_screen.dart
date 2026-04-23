import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../services/cross_section_service.dart';
import '../services/station_repository.dart';
import '../utils/app_card.dart';

class CrossSectionScreen extends StatefulWidget {
  final LatLng start;
  final LatLng end;

  const CrossSectionScreen({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  State<CrossSectionScreen> createState() => _CrossSectionScreenState();
}

class _CrossSectionScreenState extends State<CrossSectionScreen> {
  double _buffer = 500.0;
  double _exaggeration = 2.0;
  final _service = CrossSectionService();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final data = _service.generateProfile(
      start: widget.start,
      end: widget.end,
      stations: repo.stations,
      bufferMeters: _buffer,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Geologik Kesim (Profile)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Settings Panel
          _buildSettings(colorScheme),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AppCard(
                baseColor: Colors.white.withValues(alpha: 0.05),
                borderRadius: 20,
                child: ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ProfilePainter(
                      data: data,
                      exaggeration: _exaggeration,
                      totalLength: const Distance().as(LengthUnit.Meter, widget.start, widget.end),
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          _buildStatsSummary(data),
        ],
      ),
    );
  }

  Widget _buildSettings(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.line_weight, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Buffer (Masofa): ${_buffer.toInt()} m', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Slider(
                value: _buffer,
                min: 50,
                max: 2000,
                divisions: 39,
                onChanged: (v) => setState(() => _buffer = v),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.height, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Exaggeration (Bo\'rttirish): ${_exaggeration.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Slider(
                value: _exaggeration,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                onChanged: (v) => setState(() => _exaggeration = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<CrossSectionData> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Nuqtalar', data.length.toString(), Icons.analytics),
          _statItem('Masofa', '${const Distance().as(LengthUnit.Meter, widget.start, widget.end).toInt()} m', Icons.straighten),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white30, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final List<CrossSectionData> data;
  final double exaggeration;
  final double totalLength;
  final ColorScheme colorScheme;

  _ProfilePainter({
    required this.data,
    required this.exaggeration,
    required this.totalLength,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalLength == 0) return;

    // Removed unused paint variable

    // 1. Calculate Scales
    final double padding = 40.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);
    
    final double horizontalScale = drawWidth / totalLength;
    
    // Find altitude range for vertical scale
    double minAlt = 0;
    double maxAlt = 100;
    if (data.isNotEmpty) {
      minAlt = data.map((d) => d.station.altitude).reduce(min) - 100;
      maxAlt = data.map((d) => d.station.altitude).reduce(max) + 100;
    }
    final double altRange = max(100, maxAlt - minAlt);
    // Removed unused verticalScale variable

    // 2. Draw Grid Boxes
    _drawGrid(canvas, size, padding, drawWidth, drawHeight, minAlt, maxAlt, totalLength);

    // 3. Draw Topography (Surface line connecting stations)
    final surfacePath = ui.Path();
    bool first = true;
    
    // Removed unused pointPaint variable
    final dipPaint = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round;

    for (var d in data) {
      final double x = padding + (d.distanceAlongProfile * horizontalScale);
      // Flip Y (0 is top)
      final double y = size.height - padding - ((d.station.altitude - minAlt) * (drawHeight / altRange));

      if (first) {
        surfacePath.moveTo(x, y);
        first = false;
      } else {
        surfacePath.lineTo(x, y);
      }

      // Draw "Dip Stick"
      final double angleRad = d.apparentDip * pi / 180.0;
      final double stickLen = 30.0;
      
      dipPaint.color = _getDipColor(d.apparentDip);
      
      // Calculate stick endpoints
      // Note: Apparent dip is angle from horizontal. 
      // If we are looking from the side, a 45 degree dip is a line.
      final dx = stickLen * cos(angleRad);
      final dy = stickLen * sin(angleRad) * exaggeration; // Apply exaggeration to the slope

      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx, y + dy),
        dipPaint,
      );

      // Station Point
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      
      // Label
      final TextPainter tp = TextPainter(
        text: TextSpan(text: d.station.name, style: const TextStyle(color: Colors.white, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - 15));
    }

    // Draw Surface Line
    canvas.drawPath(
      surfacePath,
      Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double w, double h, double minAlt, double maxAlt, double len) {
    final gridPaint = Paint()..color = Colors.white10..strokeWidth = 0.5;
    
    // Vertical lines (Distance)
    for (double d = 0; d <= len; d += len / 5) {
      final double x = padding + (d * (w / len));
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
      
      _drawText(canvas, '${d.toInt()}m', Offset(x - 10, size.height - padding + 5));
    }

    // Horizontal lines (Altitude)
    final double range = maxAlt - minAlt;
    for (double a = minAlt; a <= maxAlt; a += range / 5) {
      final double y = size.height - padding - ((a - minAlt) * (h / range));
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
      
      _drawText(canvas, '${a.toInt()}m', Offset(padding - 35, y - 5));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  Color _getDipColor(double dip) {
    if (dip > 70) return Colors.redAccent;
    if (dip > 45) return Colors.orangeAccent;
    if (dip > 20) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.data != data ||
      old.exaggeration != exaggeration ||
      old.totalLength != totalLength;
}
