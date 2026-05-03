import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/geology_utils.dart';

void showFisherReliabilityDetailSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1D21),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scroll) {
          return Consumer<StationRepository>(
            builder: (context, repo, __) {
              final stations = repo.stations;
              final strikes = stations.map((s) => s.strike).toList();
              final stats = GeologyUtils.fisherStats(strikes);
              final s = GeoFieldStrings.of(context)!;
              return ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    context.loc('fisher_reliability'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: InteractiveViewer(
                      minScale: 0.6,
                      maxScale: 4,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: _FisherConePainter(
                            meanStrikeDeg: stats.meanAngle,
                            alpha95: stats.alpha95,
                            n: stats.n,
                            rBar: stats.resultantLength,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'α₉₅ = ${stats.alpha95.isNaN ? '—' : '${stats.alpha95.toStringAsFixed(1)}°'}  ·  n = ${stats.n}  ·  R̄ = ${stats.resultantLength.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.fisher_reliability_help,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

class _FisherConePainter extends CustomPainter {
  _FisherConePainter({
    required this.meanStrikeDeg,
    required this.alpha95,
    required this.n,
    required this.rBar,
  });

  final double meanStrikeDeg;
  final double alpha95;
  final int n;
  final double rBar;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.38;

    void ray(double strikeDeg, Paint p) {
      final rad = strikeDeg * math.pi / 180;
      final dx = r * math.sin(rad);
      final dy = -r * math.cos(rad);
      canvas.drawLine(c, c + Offset(dx, dy), p);
    }

    final outline = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r, outline);

    final mean = meanStrikeDeg;
    if (!alpha95.isNaN && n >= 2 && mean.isFinite) {
      final a1 = mean - alpha95 / 2;
      final a2 = mean + alpha95 / 2;
      final path = Path()..moveTo(c.dx, c.dy);
      const segments = 24;
      for (var i = 0; i <= segments; i++) {
        final t = a1 + (a2 - a1) * (i / segments);
        final rad = t * math.pi / 180;
        final p = c + Offset(r * math.sin(rad), -r * math.cos(rad));
        if (i == 0) {
          path.lineTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.orange.withValues(alpha: 0.35),
      );
    }

    final pMean = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (mean.isFinite) {
      ray(mean, pMean);
    }

    final pEdge = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    if (!alpha95.isNaN && n >= 2 && mean.isFinite) {
      ray(mean - alpha95 / 2, pEdge);
      ray(mean + alpha95 / 2, pEdge);
    }
  }

  @override
  bool shouldRepaint(covariant _FisherConePainter oldDelegate) {
    return oldDelegate.meanStrikeDeg != meanStrikeDeg ||
        oldDelegate.alpha95 != alpha95 ||
        oldDelegate.n != n ||
        oldDelegate.rBar != rBar;
  }
}
