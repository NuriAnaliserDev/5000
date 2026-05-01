import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geofield_pro_flutter/utils/geological_plane_projector.dart';
import 'package:geofield_pro_flutter/utils/geology_utils.dart';

/// Stereonet uslubidagi ikki tekislik (qizil/ko‘k) + halqalar + tooltiplar.
/// Dip yo‘nalishi: [GeologyUtils.calculateDipDirection].
class StereonetPlaneData {
  final double strikeDeg;
  final double dipDeg;
  final double azimuthDeg;

  const StereonetPlaneData({
    required this.strikeDeg,
    required this.dipDeg,
    required this.azimuthDeg,
  });

  double get dipDirectionDeg => GeologyUtils.calculateDipDirection(strikeDeg);

  String get dipDirectionLabel {
    final d = dipDirectionDeg;
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((d + 22.5) / 45).floor() % 8;
    return labels[i];
  }
}

class StereonetOverlayLayer extends StatelessWidget {
  final StereonetPlaneData data;

  /// Sun’iy gorizont: roll / pitch ([computeFocusModeGeometry]). `null` bo‘lsa tekislik siljimasdan chiziladi.
  final FocusModeOverlayGeometry? motion;

  /// Instrument markazi (0–1): crosshair bilan mos, odatda `0.34`.
  final double centerYFactor;

  const StereonetOverlayLayer({
    super.key,
    required this.data,
    this.motion,
    this.centerYFactor = 0.34,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StereonetPainter(
        data: data,
        motion: motion,
        centerYFactor: centerYFactor,
      ),
    );
  }
}

class _StereonetPainter extends CustomPainter {
  _StereonetPainter({
    required this.data,
    this.motion,
    required this.centerYFactor,
  });

  final StereonetPlaneData data;
  final FocusModeOverlayGeometry? motion;
  final double centerYFactor;

  double _north(double angleDeg) => _rad(angleDeg - data.azimuthDeg);

  @override
  void paint(Canvas canvas, Size size) {
    final cxScreen = size.width / 2;
    final cyScreen = size.height * centerYFactor;
    final rx = size.width * 0.36;
    final ry = rx * 0.77;

    final g = motion;
    if (g != null) {
      canvas.save();
      canvas.translate(cxScreen, cyScreen);
      canvas.rotate(-g.rollRad);
      canvas.translate(0, g.pitchOffsetPx);
      _drawHorizonLine(canvas, size);
      _drawStereonetContent(canvas, size, 0, 0, rx, ry);
      canvas.restore();
    } else {
      _drawStereonetContent(canvas, size, cxScreen, cyScreen, rx, ry);
    }
  }

  void _drawHorizonLine(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(-size.width, 0),
      Offset(size.width, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1.0,
    );
  }

  /// Barcha stereonet unsurlari markaz `(cx, cy)` atrofida.
  void _drawStereonetContent(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    _drawRings(canvas, cx, cy, rx, ry);
    _drawCardinalMarkers(canvas, cx, cy, rx, ry);
    _drawRedPlane(canvas, cx, cy, rx, ry);
    _drawBluePlane(canvas, cx, cy, rx, ry);
    _drawTooltips(canvas, cx, cy, rx, ry, size);
  }

  void _drawRings(Canvas canvas, double cx, double cy, double rx, double ry) {
    void ring(double scale, double opacity, double width) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2 * scale,
          height: ry * 2 * scale,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }

    ring(1.00, 0.90, 2.5);
    ring(0.68, 0.45, 1.5);
    ring(0.36, 0.25, 1.2);
  }

  void _drawCardinalMarkers(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    void card(double deg, String letter, _CardinalStyle style) {
      final a = _north(deg);
      _drawLabel(
        canvas,
        letter,
        cx + rx * 1.05 * math.sin(a),
        cy - ry * 1.05 * math.cos(a),
        style: style,
      );
    }

    card(0, 'N', _CardinalStyle.north);
    card(90, 'E', _CardinalStyle.minor);
    card(180, 'S', _CardinalStyle.major);
    card(270, 'W', _CardinalStyle.minor);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required _CardinalStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: style.color,
          fontSize: style.fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 5),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _drawRedPlane(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final center = _north(data.strikeDeg);
    final half = _rad(data.dipDeg * 0.45 + 12);

    _drawPlane(
      canvas,
      cx,
      cy,
      rx,
      ry,
      centerAngle: center,
      halfSpread: half,
      fillColor: const Color(0xFFE53935).withValues(alpha: 0.42),
      strokeColor: const Color(0xFFE53935).withValues(alpha: 0.88),
    );
  }

  void _drawBluePlane(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final center = _north(data.dipDirectionDeg);
    final half = _rad(data.dipDeg * 0.45 + 12);

    _drawPlane(
      canvas,
      cx,
      cy,
      rx,
      ry,
      centerAngle: center,
      halfSpread: half,
      fillColor: const Color(0xFF1E88E5).withValues(alpha: 0.38),
      strokeColor: const Color(0xFF1E88E5).withValues(alpha: 0.88),
    );
  }

  void _drawPlane(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry, {
    required double centerAngle,
    required double halfSpread,
    required Color fillColor,
    required Color strokeColor,
  }) {
    const steps = 48;
    final path = Path()..moveTo(cx, cy);
    for (int i = 0; i <= steps; i++) {
      final a = (centerAngle - halfSpread) + (2 * halfSpread) * i / steps;
      path.lineTo(
        cx + rx * 0.94 * math.sin(a),
        cy - ry * 0.94 * math.cos(a),
      );
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(cx, cy),
      Offset(
        cx + rx * 0.94 * math.sin(centerAngle),
        cy - ry * 0.94 * math.cos(centerAngle),
      ),
      Paint()
        ..color = strokeColor
        ..strokeWidth = 2.4,
    );
  }

  void _drawTooltips(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
    Size size,
  ) {
    final tipPositions = [
      Offset(cx - rx * 0.88, cy - ry * 0.75),
      Offset(cx + rx * 0.18, cy - ry * 0.90),
      Offset(cx + rx * 0.72, cy - ry * 0.22),
    ];
    final anchors = [
      Offset(cx - rx * 0.38, cy - ry * 0.30),
      Offset(cx + rx * 0.28, cy - ry * 0.35),
      Offset(cx + rx * 0.62, cy + ry * 0.05),
    ];

    final label =
        'Strike: ${data.strikeDeg.toStringAsFixed(0)}°\n'
        'Dip: ${data.dipDeg.toStringAsFixed(0)}° ${data.dipDirectionLabel}';

    for (int i = 0; i < 3; i++) {
      _drawLeader(canvas, tipPositions[i], anchors[i]);
      _drawTooltipBox(canvas, tipPositions[i], label);
    }
  }

  void _drawLeader(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.72)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      to,
      3.2,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
  }

  void _drawTooltipBox(Canvas canvas, Offset pos, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 130);

    const pad = 6.0;
    final boxRect = Rect.fromLTWH(
      pos.dx - tp.width / 2 - pad,
      pos.dy - tp.height / 2 - pad,
      tp.width + pad * 2,
      tp.height + pad * 2,
    );
    final rr = RRect.fromRectAndRadius(boxRect, const Radius.circular(7));

    canvas.drawRRect(
      rr,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  double _rad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(_StereonetPainter old) {
    final om = old.motion;
    final m = motion;
    if (om?.rollRad != m?.rollRad ||
        om?.pitchOffsetPx != m?.pitchOffsetPx ||
        old.centerYFactor != centerYFactor) {
      return true;
    }
    return old.data.strikeDeg != data.strikeDeg ||
        old.data.dipDeg != data.dipDeg ||
        old.data.azimuthDeg != data.azimuthDeg;
  }
}

enum _CardinalStyle {
  north,
  major,
  minor;

  Color get color => switch (this) {
        _CardinalStyle.north => Colors.redAccent.shade100,
        _CardinalStyle.major => Colors.white,
        _CardinalStyle.minor => Colors.white70,
      };

  double get fontSize => switch (this) {
        _CardinalStyle.north => 18,
        _CardinalStyle.major => 17,
        _CardinalStyle.minor => 15,
      };
}
