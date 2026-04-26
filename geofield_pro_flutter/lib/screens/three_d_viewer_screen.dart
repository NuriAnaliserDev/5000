import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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
              top: 4,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    s?.viewer_3d_nothing_visible ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 100 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      s?.viewer_3d_legend ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.35,
                      ),
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
    final pad = MediaQuery.of(context).padding;
    return Positioned(
      bottom: 12 + pad.bottom,
      right: 12,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A2028),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () => setState(() => _zoom = (_zoom * 1.2).clamp(0.2, 8.0)),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () => setState(() => _zoom = (_zoom / 1.2).clamp(0.2, 8.0)),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
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

  /// Metr koordinatalarni ekran ichidagi qabul qilinadigan diapazonga qisqartiramiz
  static const double _worldScale = 0.00015;

  Offset3D _w(Offset3D p) => Offset3D(p.x * _worldScale, p.y * _worldScale, p.z * _worldScale);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final grad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2A3444), Color(0xFF0D1117)],
    );
    canvas.drawRect(r, Paint()..shader = grad.createShader(r));

    final Matrix4 viewMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..setTranslationRaw(0.0, 0.0, -2.2)
      ..rotateX(rotX * 0.9)
      ..rotateY(rotY * 0.9)
      ..scaleByDouble(zoom, zoom, 1.0, 1.0);

    for (var s in stations) {
      final localPos = ThreeDMathUtils.projectToLocal(
        LatLng(s.lat, s.lng),
        s.altitude,
        center,
        centerAlt,
      );
      final scaledCenter = _w(localPos);
      final screenPos = ThreeDMathUtils.projectToScreen(scaledCenter, viewMatrix, size);

      final planePoints = ThreeDMathUtils.getStrikeDipPlane(localPos, s.strike, s.dip, 40.0);
      final screenPlanePoints = planePoints
          .map((p) => ThreeDMathUtils.projectToScreen(_w(p), viewMatrix, size))
          .toList();
      final okPlane = screenPlanePoints.where((p) => p != Offset.zero).length >= 3;
      if (okPlane) {
        final path = ui.Path()..addPolygon(screenPlanePoints, true);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.orange.withValues(alpha: 0.35 + (s.dip / 180) * 0.3),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFB74D).withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else if (screenPos != Offset.zero) {
        _drawDipSymbol(canvas, screenPos, s.dip, s.strike);
      }

      if (screenPos != Offset.zero) {
        canvas.drawCircle(screenPos, 6, Paint()..color = Colors.white);
        canvas.drawCircle(
          screenPos,
          6,
          Paint()
            ..color = const Color(0xFF29B6F6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: s.name,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, shadows: [
              Shadow(offset: Offset(0.5, 0.5), blurRadius: 2, color: Colors.black),
            ]),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);
        tp.paint(canvas, screenPos + const Offset(8, -10));
      }
    }

    _drawGridFloor(canvas, size, viewMatrix);
    _drawAxisCross(canvas, size, viewMatrix);
  }

  void _drawDipSymbol(Canvas canvas, Offset c, double dip, double strike) {
    final rad = strike * math.pi / 180;
    final dx = 14 * math.sin(rad);
    final dy = -14 * math.cos(rad);
    canvas.drawLine(
      c - Offset(dx, dy) * 0.4,
      c + Offset(dx, dy) * 0.4,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 1.5,
    );
    final tp = TextPainter(
      text: TextSpan(text: '${dip.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.cyanAccent, fontSize: 7)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + const Offset(6, 0));
  }

  void _drawGridFloor(Canvas canvas, Size size, Matrix4 viewMatrix) {
    final paint = Paint()
      ..color = const Color(0xFF6B7A8E).withValues(alpha: 0.5)
      ..strokeWidth = 1.1;
    const double stepM = 80.0;
    const int count = 8;
    for (int i = -count; i <= count; i++) {
      final p1 = _w(Offset3D(i * stepM, -count * stepM, 0));
      final p2 = _w(Offset3D(i * stepM, count * stepM, 0));
      final s1 = ThreeDMathUtils.projectToScreen(p1, viewMatrix, size);
      final s2 = ThreeDMathUtils.projectToScreen(p2, viewMatrix, size);
      if (s1 != Offset.zero && s2 != Offset.zero) {
        canvas.drawLine(s1, s2, paint);
      }
      final p3 = _w(Offset3D(-count * stepM, i * stepM, 0));
      final p4 = _w(Offset3D(count * stepM, i * stepM, 0));
      final a = ThreeDMathUtils.projectToScreen(p3, viewMatrix, size);
      final b = ThreeDMathUtils.projectToScreen(p4, viewMatrix, size);
      if (a != Offset.zero && b != Offset.zero) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  void _drawAxisCross(Canvas canvas, Size size, Matrix4 viewMatrix) {
    final o = _w(Offset3D(0, 0, 0));
    const ax = 0.4;
    final ox = ThreeDMathUtils.projectToScreen(o, viewMatrix, size);
    if (ox == Offset.zero) return;
    final ex = ThreeDMathUtils.projectToScreen(_w(Offset3D(ax, 0, 0)), viewMatrix, size);
    final ey = ThreeDMathUtils.projectToScreen(_w(Offset3D(0, ax, 0)), viewMatrix, size);
    if (ex != Offset.zero) {
      canvas.drawLine(ox, ex, Paint()..color = Colors.redAccent..strokeWidth = 1.2);
    }
    if (ey != Offset.zero) {
      canvas.drawLine(ox, ey, Paint()..color = Colors.lightGreen..strokeWidth = 1.2);
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
