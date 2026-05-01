import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geofield_pro_flutter/utils/geological_plane_projector.dart';
import 'package:geofield_pro_flutter/utils/geology_utils.dart';

/// Stereonet uslubidagi ikki tekislik (qizil/ko‘k) + halqalar + tooltiplar.
/// Tekisliklar: [StereonetEngine.calculateGreatCircle] (Schmidt, past yarim sfera).
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

  /// Sun’iy gorizont: roll/pitch ([computeFocusModeGeometry]). Stereografik doira roll bilan
  /// aylanmaydi (qog‘oz stereonet bilan solishtirish); faqat gorizont chizig‘i roll qiladi.
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

  static const StereonetProjection _proj = StereonetProjection.schmidt;

  double _north(double angleDeg) => _rad(angleDeg - data.azimuthDeg);

  /// [motion] da `compassRotationRad` bilan bir xil ma’no: shimol telefon frame ga.
  Offset _mapStereonetToCanvas(Offset stereonetOffset, double cx, double cy) {
    final o = StereonetEngine.rotateStereonetByAzimuth(
      stereonetOffset,
      data.azimuthDeg,
    );
    return Offset(cx + o.dx, cy + o.dy);
  }

  Path? _greatCirclePath(
    List<Offset> geoRelative,
    double cx,
    double cy,
    double netR,
  ) {
    if (geoRelative.length < 2) return null;
    final path = Path();
    var moved = false;
    Offset? prev;
    final jumpTh = netR * 0.18;
    for (final p in geoRelative) {
      final cur = _mapStereonetToCanvas(p, cx, cy);
      if (!moved) {
        path.moveTo(cur.dx, cur.dy);
        moved = true;
      } else {
        if (prev != null && (cur - prev).distance > jumpTh) {
          path.moveTo(cur.dx, cur.dy);
        } else {
          path.lineTo(cur.dx, cur.dy);
        }
      }
      prev = cur;
    }
    return moved ? path : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cxScreen = size.width / 2;
    final cyScreen = size.height * centerYFactor;
    final netR = size.width * 0.36;

    final g = motion;
    if (g != null) {
      // Stereonet geografik frame da: roll qo‘llanmaydi (qog‘oz stereonet bilan solishtirish).
      canvas.save();
      canvas.translate(cxScreen, cyScreen);
      canvas.translate(0, g.pitchOffsetPx);
      _drawStereonetContent(canvas, size, 0, 0, netR);
      canvas.restore();

      canvas.save();
      canvas.translate(cxScreen, cyScreen);
      canvas.rotate(-g.rollRad);
      canvas.translate(0, g.pitchOffsetPx);
      _drawHorizonLine(canvas, size);
      canvas.restore();
    } else {
      _drawStereonetContent(canvas, size, cxScreen, cyScreen, netR);
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

  void _drawStereonetContent(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double netR,
  ) {
    _drawRings(canvas, cx, cy, netR);
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(
          Rect.fromCircle(center: Offset(cx, cy), radius: netR),
        ),
    );
    _drawVerticalPlaneGreatCircle(canvas, cx, cy, netR);
    _drawBedPlaneGreatCircle(canvas, cx, cy, netR);
    _drawDipLine(canvas, cx, cy, netR);
    canvas.restore();
    _drawCardinalMarkers(canvas, cx, cy, netR);
    _drawTooltips(canvas, cx, cy, netR, size);
  }

  void _drawRings(Canvas canvas, double cx, double cy, double netR) {
    void ring(double scale, double opacity, double width) {
      canvas.drawCircle(
        Offset(cx, cy),
        netR * scale,
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
    double netR,
  ) {
    void card(double deg, String letter, _CardinalStyle style) {
      final a = _north(deg);
      _drawLabel(
        canvas,
        letter,
        cx + netR * 1.05 * math.sin(a),
        cy - netR * 1.05 * math.cos(a),
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

  /// Qatlam tekisligi — Schmidt great circle (past yarim sfera).
  void _drawBedPlaneGreatCircle(
    Canvas canvas,
    double cx,
    double cy,
    double netR,
  ) {
    final pts = StereonetEngine.calculateGreatCircle(
      strike: data.strikeDeg,
      dip: data.dipDeg,
      radius: netR,
      proj: _proj,
    );
    final path = _greatCirclePath(pts, cx, cy, netR);
    if (path == null) return;
    final stroke = const Color(0xFFE53935).withValues(alpha: 0.92);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Dip yo‘nalishidagi vertikal tekislik (strike ⟂ dip dir., dip = 90°).
  void _drawVerticalPlaneGreatCircle(
    Canvas canvas,
    double cx,
    double cy,
    double netR,
  ) {
    final strikeVert = (data.dipDirectionDeg - 90.0 + 360.0) % 360.0;
    final pts = StereonetEngine.calculateGreatCircle(
      strike: strikeVert,
      dip: 90,
      radius: netR,
      proj: _proj,
    );
    final path = _greatCirclePath(pts, cx, cy, netR);
    if (path == null) return;
    final stroke = const Color(0xFF1E88E5).withValues(alpha: 0.88);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Qatlam bo‘yicha eng qiya chiziq (dip yo‘nalishi, moyil = dip).
  void _drawDipLine(Canvas canvas, double cx, double cy, double netR) {
    if (data.dipDeg <= 0) return;
    final rel = StereonetEngine.projectLineation(
      trendDeg: data.dipDirectionDeg,
      plungeDeg: data.dipDeg,
      radius: netR,
      proj: _proj,
    );
    if (rel.distance < 1.0) return;
    final tip = _mapStereonetToCanvas(rel, cx, cy);
    final stroke = const Color(0xFFE53935).withValues(alpha: 0.95);
    canvas.drawLine(
      Offset(cx, cy),
      tip,
      Paint()
        ..color = stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTooltips(
    Canvas canvas,
    double cx,
    double cy,
    double netR,
    Size size,
  ) {
    final tipPositions = [
      Offset(cx - netR * 0.88, cy - netR * 0.75),
      Offset(cx + netR * 0.18, cy - netR * 0.90),
      Offset(cx + netR * 0.72, cy - netR * 0.22),
    ];
    final anchors = [
      Offset(cx - netR * 0.38, cy - netR * 0.30),
      Offset(cx + netR * 0.28, cy - netR * 0.35),
      Offset(cx + netR * 0.62, cy + netR * 0.05),
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
