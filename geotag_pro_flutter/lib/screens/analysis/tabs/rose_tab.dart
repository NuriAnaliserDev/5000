import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_scroll_physics.dart';
import '../components/analysis_info_tile.dart';

// YAXSHILANISH: Dinamik bin tanlash — 8/16/36/72 bin
// FieldMove va GeoKit 36-bin (10°) ishlatadi. Endi biz ham qo'llab-quvvatlaymiz.
// Foydalanuvchi dala sharoitiga qarab optimal binni tanlay oladi.
class RoseTab extends StatefulWidget {
  const RoseTab({super.key, required this.stations});
  final List<Station> stations;

  @override
  State<RoseTab> createState() => _RoseTabState();
}

class _RoseTabState extends State<RoseTab> {
  int _binCount = 16; // default: 22.5° bins
  static const _binOptions = [8, 16, 36, 72];
  static const _binLabels = ['45°', '22.5°', '10°', '5°'];

  late List<int> _counts;
  late int _maxCount;
  late int _dominantBin;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void didUpdateWidget(RoseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stations, widget.stations) ||
        oldWidget.stations.length != widget.stations.length) {
      _compute();
    }
  }

  void _compute() {
    final counts = List<int>.filled(_binCount, 0);
    final binSize = 360.0 / _binCount;
    for (final s in widget.stations) {
      final bin = ((s.strike % 360) / binSize).floor() % _binCount;
      counts[bin]++;
    }
    _counts = counts;
    _maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 0;
    _dominantBin = _maxCount > 0 ? counts.indexOf(_maxCount) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final binSize = 360.0 / _binCount;
    final dominantDeg = (_dominantBin * binSize + binSize / 2).toStringAsFixed(1);

    return ListView(
      physics: AppScrollPhysics.list(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.loc('rose_diagram_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: onSurf.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.loc('rose_diagram_subtitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // ── Bin tanlash (FieldMove kabi) ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bin: ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: onSurf.withValues(alpha: 0.6)),
            ),
            ...List.generate(_binOptions.length, (i) {
              final selected = _binCount == _binOptions[i];
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _binCount = _binOptions[i];
                      _compute();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1976D2)
                          : const Color(0xFF1976D2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _binLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // ── Rose Diagram ─────────────────────────────────────────────────
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: RoseDiagramPainter(
                counts: _counts,
                maxCount: _maxCount,
                isDark: isDark,
                binCount: _binCount,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnalysisInfoTile(
          icon: Icons.rotate_right,
          label: context.loc('dominant_direction'),
          value: '$dominantDeg°',
        ),
        AnalysisInfoTile(
          icon: Icons.layers,
          label: context.loc('total_stations_short'),
          value: '${widget.stations.length}',
        ),
        const SizedBox(height: 24),

        // ── Bin Table ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? const Color(0xFF181818) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF1976D2).withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: List.generate(_binCount, (i) {
              final deg = (i * binSize).toStringAsFixed(
                  _binCount > 16 ? 0 : 0);
              final cnt = _counts[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: cnt == _maxCount && _maxCount > 0
                      ? const Color(0xFF1976D2)
                      : const Color(0xFF1976D2).withValues(
                          alpha: cnt > 0 ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$deg°: $cnt',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cnt == _maxCount && _maxCount > 0
                        ? Colors.white
                        : onSurf.withValues(alpha: 0.7),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class RoseDiagramPainter extends CustomPainter {
  final List<int> counts;
  final int maxCount;
  final bool isDark;
  final int binCount;

  RoseDiagramPainter({
    required this.counts,
    required this.maxCount,
    required this.isDark,
    this.binCount = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 12;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
    );

    final ringPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 4, ringPaint);
    }

    // Radial lines — bin soniga qarab
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..strokeWidth = 0.8;
    final lineCount = binCount > 36 ? 8 : (binCount > 16 ? 12 : 8);
    for (int i = 0; i < lineCount; i++) {
      final angle = i * pi / (lineCount / 2) - pi / 2;
      canvas.drawLine(
        Offset(cx + cos(angle) * r, cy + sin(angle) * r),
        Offset(cx - cos(angle) * r, cy - sin(angle) * r),
        linePaint,
      );
    }

    final sectorRad = 2 * pi / binCount;
    for (int i = 0; i < binCount; i++) {
      final ct = counts[i];
      if (ct == 0) continue;
      final fraction = maxCount > 0 ? ct / maxCount : 0.0;
      final petalR = r * fraction;

      final startAngle = i * sectorRad - pi / 2;
      for (final offset in [0.0, pi]) {
        final path = Path()..moveTo(cx, cy);
        path.arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: petalR),
          startAngle + offset - sectorRad / 2,
          sectorRad,
          false,
        );
        path.close();

        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1976D2)
                .withValues(alpha: ct == maxCount ? 0.85 : 0.45)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1976D2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    void drawLabel(String text, Offset pos) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    drawLabel('N', Offset(cx, cy - r - 14));
    drawLabel('S', Offset(cx, cy + r + 14));
    drawLabel('E', Offset(cx + r + 14, cy));
    drawLabel('W', Offset(cx - r - 14, cy));
  }

  @override
  bool shouldRepaint(RoseDiagramPainter old) =>
      !listEquals(old.counts, counts) ||
      old.isDark != isDark ||
      old.binCount != binCount;
}
