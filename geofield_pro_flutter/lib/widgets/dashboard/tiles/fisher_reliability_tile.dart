import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_card.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/app_localizations.dart';
import 'fisher_reliability_detail_sheet.dart';

class FisherReliabilityTile extends StatefulWidget {
  final bool isDark;

  const FisherReliabilityTile({
    super.key,
    required this.isDark,
  });

  @override
  State<FisherReliabilityTile> createState() => _FisherReliabilityTileState();
}

class _FisherReliabilityTileState extends State<FisherReliabilityTile> {
  int? _cachedDataGeneration;
  FisherStats? _stats;

  void _maybeRecompute(StationRepository repo) {
    final gen = repo.dataGeneration;
    if (_cachedDataGeneration == gen && _stats != null) {
      return;
    }
    _cachedDataGeneration = gen;
    final strikes = repo.stations.map((s) => s.strike).toList();
    _stats = GeologyUtils.fisherStatsAxial(strikes);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    _maybeRecompute(repo);
    if (_stats == null) {
      return const SizedBox.shrink();
    }
    final stats = _stats!;
    final hasEnoughData = stats.n >= 5;
    final reliable = hasEnoughData && stats.isReliable;
    final pct = !hasEnoughData
        ? 0
        : reliable
            ? 95
            : (100 -
                    (stats.alpha95.isNaN
                        ? 40
                        : math.min(stats.alpha95 * 4, 80)))
                .round()
                .clamp(15, 85);
    final accent = !hasEnoughData
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : reliable
            ? const Color(0xFF4A90E2)
            : Colors.orange;
    final s = GeoFieldStrings.of(context);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showFisherReliabilityDetailSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.loc('fisher_reliability'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => showFisherReliabilityDetailSheet(context),
                    icon: Icon(Icons.zoom_in_map,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    tooltip: context.loc('fisher_stats'),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 72),
                      painter: _SemiGaugePainter(
                        progress: pct / 100,
                        color: accent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasEnoughData ? '$pct%' : 'n=${stats.n}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        Text(
                          !hasEnoughData
                              ? context.loc('no_data')
                              : reliable
                                  ? (s?.fisher_gauge_high ??
                                      'Yuqori ishonchlilik')
                                  : context.loc('fisher_dispersion'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: reliable ? accent : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 22,
                child: CustomPaint(
                  painter:
                      _MiniWavePainter(color: accent.withValues(alpha: 0.55)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _SemiGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.92);
    final r = size.width * 0.38;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const start = math.pi;
    final sweep = math.pi * progress;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, math.pi, false, bg);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _MiniWavePainter extends CustomPainter {
  final Color color;

  _MiniWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.6);
    for (var i = 0; i <= 40; i++) {
      final x = w * (i / 40);
      final y = h * 0.5 + math.sin(i * 0.45) * h * 0.35;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(Offset(6, h * 0.55), 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
