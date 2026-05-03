import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/station.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_scroll_physics.dart';
import '../../../utils/geology_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Statistika: [_StationStats] Yangilanishi — [StationRepository.dataGeneration]
// orqali (Hive obyekti tahrirlanganda ham strike/dip qayta o‘qiladi).
// ─────────────────────────────────────────────────────────────────────────────
class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key, required this.stations});
  final List<Station> stations;

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  // Pre-computed values — Hive stansiyasi tahrirlanda ham yangilanishi uchun
  // faqat ro'yxat uzunligi/key emas, [StationRepository.dataGeneration] garov.
  late _StationStats _stats;
  int? _statsGeneration;

  @override
  void initState() {
    super.initState();
    _stats = _StationStats.compute(widget.stations);
  }

  @override
  void didUpdateWidget(StatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stations.length != widget.stations.length) {
      _stats = _StationStats.compute(widget.stations);
      _statsGeneration = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataGen = context.watch<StationRepository>().dataGeneration;
    if (_statsGeneration != dataGen) {
      _statsGeneration = dataGen;
      _stats = _StationStats.compute(widget.stations);
    }
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.grey.shade100;
    final s = _stats;

    Widget statRow(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: onSurf.withValues(alpha: 0.7), fontSize: 13)),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF1976D2),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    Widget card(String title, Widget child) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1976D2).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w900)),
              const Divider(height: 16, color: Color(0xFF1976D2)),
              child,
            ],
          ),
        );

    return ListView(
      physics: AppScrollPhysics.list(),
      padding: const EdgeInsets.all(16),
      children: [
        card(
            context.loc('analysis_general'),
            Column(children: [
              statRow('${context.loc('analysis_station_count')}:',
                  '${s.totalCount}'),
              statRow('${context.loc('analysis_project_count')}:',
                  '${s.projectCount}'),
              statRow('${context.loc('analysis_with_gps')}:', '${s.withGps}'),
              if (s.minAlt.isFinite && s.maxAlt.isFinite)
                statRow('${context.loc('analysis_alt_range')}:',
                    '${s.minAlt.toStringAsFixed(0)} – ${s.maxAlt.toStringAsFixed(0)} m'),
            ])),
        card(
            context.loc('analysis_orientation_mean'),
            Column(children: [
              statRow('${context.loc('analysis_circular_mean_strike')}:',
                  '${s.avgStrike.toStringAsFixed(1)}°'),
              statRow('${context.loc('analysis_avg_dip')}:',
                  '${s.avgDip.toStringAsFixed(1)}°'),
              statRow('${context.loc('analysis_dip_direction')}:',
                  '${((s.avgStrike + 90) % 360).toStringAsFixed(1)}°'),
              statRow('${context.loc('analysis_strike_std')}:',
                  '${s.strikeStdDev.isNaN ? "—" : s.strikeStdDev.toStringAsFixed(1)}°'),
            ])),
        card(
            context.loc('analysis_fisher_stats'),
            Column(children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('n',
                          style: TextStyle(
                              fontSize: 10,
                              color: onSurf.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold)),
                      Text('${s.fisher.n}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1976D2))),
                    ])),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('R (Resultant)',
                          style: TextStyle(
                              fontSize: 10,
                              color: onSurf.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold)),
                      Text(
                          s.fisher.resultantLength.isNaN
                              ? '—'
                              : s.fisher.resultantLength.toStringAsFixed(3),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1976D2))),
                    ])),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('κ (Kappa)',
                          style: TextStyle(
                              fontSize: 10,
                              color: onSurf.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold)),
                      Text(
                          s.fisher.kappa.isNaN
                              ? '—'
                              : s.fisher.kappa.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1976D2))),
                    ])),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('α₉₅ (°)',
                          style: TextStyle(
                              fontSize: 10,
                              color: onSurf.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold)),
                      Text(
                          s.fisher.alpha95.isNaN
                              ? '—'
                              : '±${s.fisher.alpha95.toStringAsFixed(1)}°',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: s.fisher.isReliable
                                  ? Colors.green
                                  : Colors.orange)),
                    ])),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (s.fisher.isReliable ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          (s.fisher.isReliable ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(
                      s.fisher.isReliable
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      size: 14,
                      color:
                          s.fisher.isReliable ? Colors.green : Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                    s.fisher.isReliable
                        ? context.loc('analysis_stat_reliable')
                        : context.loc('analysis_stat_unreliable'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: s.fisher.isReliable ? Colors.green : Colors.orange,
                    ),
                  )),
                ]),
              ),
            ])),
        card(
            context.loc('analysis_projects'),
            Column(
              children: s.byProject.entries.map((e) {
                final pct = (e.value / s.totalCount * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(e.key,
                                    style: TextStyle(
                                        color: onSurf,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))),
                            Text('${e.value} ($pct%)',
                                style: const TextStyle(
                                    color: Color(0xFF1976D2),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / s.totalCount,
                          minHeight: 5,
                          backgroundColor:
                              const Color(0xFF1976D2).withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1976D2)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )),
        card(
            context.loc('analysis_rocks'),
            Column(
              children: (s.byRockType.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .take(8)
                  .map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(e.key,
                                style: TextStyle(color: onSurf, fontSize: 12))),
                        Text('${e.value}',
                            style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ]),
                );
              }).toList(),
            )),
        card(
            context.loc('analysis_measure_types'),
            Column(
              children: s.byMeasurement.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900)),
                            ]),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}

/// Pre-computed statistics — build() dan tashqarida hisoblanadi
class _StationStats {
  final int totalCount;
  final int projectCount;
  final int withGps;
  final double minAlt;
  final double maxAlt;
  final double avgStrike;
  final double avgDip;
  final double strikeStdDev;
  final FisherStats fisher;
  final Map<String, int> byProject;
  final Map<String, int> byRockType;
  final Map<String, int> byMeasurement;

  const _StationStats({
    required this.totalCount,
    required this.projectCount,
    required this.withGps,
    required this.minAlt,
    required this.maxAlt,
    required this.avgStrike,
    required this.avgDip,
    required this.strikeStdDev,
    required this.fisher,
    required this.byProject,
    required this.byRockType,
    required this.byMeasurement,
  });

  factory _StationStats.compute(List<Station> stations) {
    if (stations.isEmpty) {
      return _StationStats(
        totalCount: 0,
        projectCount: 0,
        withGps: 0,
        minAlt: double.infinity,
        maxAlt: double.negativeInfinity,
        avgStrike: 0,
        avgDip: 0,
        strikeStdDev: double.nan,
        fisher: FisherStats(
            n: 0,
            meanAngle: double.nan,
            resultantLength: 0,
            kappa: double.nan,
            alpha95: double.nan,
            isReliable: false),
        byProject: {},
        byRockType: {},
        byMeasurement: {},
      );
    }

    final byProject = <String, int>{};
    final byRockType = <String, int>{};
    final byMeasurement = <String, int>{};
    double sumDip = 0;
    int withGps = 0;
    double minAlt = double.infinity;
    double maxAlt = double.negativeInfinity;
    final strikes = <double>[];
    final axialStrikes = <double>[];
    final unimodalStrikes = <double>[];

    for (final s in stations) {
      byProject[s.project ?? 'Default'] =
          (byProject[s.project ?? 'Default'] ?? 0) + 1;
      byRockType[s.rockType ?? '—'] = (byRockType[s.rockType ?? '—'] ?? 0) + 1;
      byMeasurement[s.measurementType ?? 'bedding'] =
          (byMeasurement[s.measurementType ?? 'bedding'] ?? 0) + 1;

      final type = s.measurementType ?? 'bedding';
      if (type == 'bedding' || type == 'cleavage' || type == 'foliation') {
        axialStrikes.add(s.strike);
      } else {
        unimodalStrikes.add(s.strike);
      }

      strikes.add(s.strike);
      sumDip += s.dip;
      if (s.lat != 0 || s.lng != 0) withGps++;
      if (s.altitude < minAlt) minAlt = s.altitude;
      if (s.altitude > maxAlt) maxAlt = s.altitude;
    }

    return _StationStats(
      totalCount: stations.length,
      projectCount: byProject.length,
      withGps: withGps,
      minAlt: minAlt,
      maxAlt: maxAlt,
      avgStrike: GeologyUtils.circularMean(strikes),
      avgDip: sumDip / stations.length,
      strikeStdDev: GeologyUtils.circularStdDev(strikes),
      fisher: axialStrikes.isNotEmpty
          ? GeologyUtils.fisherStatsAxial(axialStrikes)
          : GeologyUtils.fisherStats(unimodalStrikes),
      byProject: byProject,
      byRockType: byRockType,
      byMeasurement: byMeasurement,
    );
  }
}
