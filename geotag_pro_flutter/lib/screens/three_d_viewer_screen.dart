import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../l10n/app_strings.dart';
import '../models/station.dart';
import '../services/station_repository.dart';
import '../utils/three_d_math_utils.dart';

class ThreeDViewerScreen extends StatefulWidget {
  final LatLng? centerPoint;
  const ThreeDViewerScreen({super.key, this.centerPoint});

  @override
  State<ThreeDViewerScreen> createState() => _ThreeDViewerScreenState();
}

class _ThreeDViewerScreenState extends State<ThreeDViewerScreen> {
  double _rotationX = 0.5;
  double _rotationY = 0.5;
  double _zoom = 1.0;
  
  late LatLng _center;
  late double _avgAlt;

  @override
  void initState() {
    super.initState();
    final repo = context.read<StationRepository>();
    final stations = repo.stations;
    
    if (stations.isNotEmpty) {
      _center = widget.centerPoint ?? LatLng(stations.first.lat, stations.first.lng);
      _avgAlt = stations.map((e) => e.altitude).reduce((a, b) => a + b) / stations.length;
    } else {
      _center = const LatLng(0, 0);
      _avgAlt = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationRepository>().stations;
    final s = GeoFieldStrings.of(context);

    if (stations.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: Text(
            s?.three_d_structure ?? '3D',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s?.viewer_3d_no_data ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          s?.three_d_structure ?? '3D',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _rotationX = 0.5;
              _rotationY = 0.5;
              _zoom = 1.0;
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _rotationY += details.delta.dx * 0.01;
            _rotationX -= details.delta.dy * 0.01;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: Structural3DPainter(
                  stations: stations,
                  center: _center,
                  centerAlt: _avgAlt,
                  rotX: _rotationX,
                  rotY: _rotationY,
                  zoom: _zoom,
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 8,
              right: 72,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    s?.viewer_3d_legend ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () => setState(() => _zoom *= 1.2),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () => setState(() => _zoom /= 1.2),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

class Structural3DPainter extends CustomPainter {
  final List<Station> stations;
  final LatLng center;
  final double centerAlt;
  final double rotX;
  final double rotY;
  final double zoom;

  Structural3DPainter({
    required this.stations,
    required this.center,
    required this.centerAlt,
    required this.rotX,
    required this.rotY,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Matrix4 viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..setTranslationRaw(0.0, 0.0, -500.0) // Camera distance
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..scaleByDouble(zoom, zoom, zoom, 1.0);

    final paintPoint = Paint()..color = Colors.blue;
    final paintLine = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final paintPlane = Paint()..style = PaintingStyle.fill;

    for (var s in stations) {
      final localPos = ThreeDMathUtils.projectToLocal(LatLng(s.lat, s.lng), s.altitude, center, centerAlt);
      final screenPos = ThreeDMathUtils.projectToScreen(localPos, viewMatrix, size);

      if (screenPos == Offset.zero) continue;

      // Draw 3D plane for Strike/Dip
      final planePoints = ThreeDMathUtils.getStrikeDipPlane(localPos, s.strike, s.dip, 40.0); // 40m planes
      final screenPlanePoints = planePoints.map((p) => ThreeDMathUtils.projectToScreen(p, viewMatrix, size)).toList();

      if (screenPlanePoints.every((p) => p != Offset.zero)) {
        final path = ui.Path()..addPolygon(screenPlanePoints, true);
        
        // Color based on Dip (steeper is darker/warmer)
        canvas.drawPath(
          path, 
          paintPlane..color = Colors.orange.withValues(alpha: 0.3 + (s.dip/180))
        );
        canvas.drawPath(
          path, 
          paintLine..color = Colors.orangeAccent.withValues(alpha: 0.7)
        );
      }

      // Draw central point
      canvas.drawCircle(screenPos, 4, paintPoint..color = Colors.white);
      
      // Label
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s.name,
          style: const TextStyle(color: Colors.white70, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, screenPos + const Offset(8, -8));
    }

    // Draw grid floor (optional but helpful for orientation)
    _drawGridFloor(canvas, size, viewMatrix);
  }

  void _drawGridFloor(Canvas canvas, Size size, Matrix4 viewMatrix) {
    final paint = Paint()..color = Colors.white12..strokeWidth = 1;
    const double step = 200;
    const int count = 5;

    for (int i = -count; i <= count; i++) {
      final p1 = ThreeDMathUtils.projectToScreen(Offset3D(i * step, -count * step, 0), viewMatrix, size);
      final p2 = ThreeDMathUtils.projectToScreen(Offset3D(i * step, count * step, 0), viewMatrix, size);
      if (p1 != Offset.zero && p2 != Offset.zero) canvas.drawLine(p1, p2, paint);

      final p3 = ThreeDMathUtils.projectToScreen(Offset3D(-count * step, i * step, 0), viewMatrix, size);
      final p4 = ThreeDMathUtils.projectToScreen(Offset3D(count * step, i * step, 0), viewMatrix, size);
      if (p3 != Offset.zero && p4 != Offset.zero) canvas.drawLine(p3, p4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant Structural3DPainter oldDelegate) {
    return oldDelegate.stations != stations ||
           oldDelegate.center != center ||
           oldDelegate.centerAlt != centerAlt ||
           oldDelegate.rotX != rotX ||
           oldDelegate.rotY != rotY ||
           oldDelegate.zoom != zoom;
  }
}
