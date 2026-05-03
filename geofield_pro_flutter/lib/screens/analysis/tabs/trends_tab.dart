import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/station.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_scroll_physics.dart';
import '../../../utils/geology_utils.dart';

// PERFORMANCE FIX: StatefulWidget — hisob-kitob faqat ma'lumot o'zgarganda
class TrendsTab extends StatefulWidget {
  final List<Station> stations;
  const TrendsTab({super.key, required this.stations});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  late List<int> _dipCounts;
  late int _maxDipCount;
  late double _avgStrike;
  late FisherStats _stats;
  int? _lastRepoGen;

  @override
  void initState() {
    super.initState();
    _compute(widget.stations);
  }

  @override
  void didUpdateWidget(TrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stations, widget.stations) ||
        oldWidget.stations.length != widget.stations.length) {
      _compute(widget.stations);
    }
  }

  void _compute(List<Station> stations) {
    final dipCounts = List.filled(9, 0);
    final axialStrikes = <double>[];
    final unimodalStrikes = <double>[];

    for (var s in stations) {
      int idx = (s.dip / 10).floor().clamp(0, 8);
      dipCounts[idx]++;
      
      final type = s.measurementType ?? 'bedding';
      if (type == 'bedding' || type == 'cleavage' || type == 'foliation') {
        axialStrikes.add(s.strike);
      } else {
        unimodalStrikes.add(s.strike);
      }
    }
    _dipCounts = dipCounts;
    _maxDipCount = dipCounts.isNotEmpty ? dipCounts.reduce(max) : 1;
    _avgStrike = axialStrikes.isNotEmpty 
        ? GeologyUtils.circularMean(axialStrikes) 
        : (unimodalStrikes.isNotEmpty ? GeologyUtils.circularMean(unimodalStrikes) : 0.0);
        
    if (axialStrikes.isNotEmpty) {
      _stats = GeologyUtils.fisherStatsAxial(axialStrikes);
    } else if (unimodalStrikes.isNotEmpty) {
      _stats = GeologyUtils.fisherStats(unimodalStrikes);
    } else {
      _stats = FisherStats(
          n: 0, meanAngle: 0, resultantLength: 0,
          kappa: double.nan, alpha95: double.nan, isReliable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<StationRepository>().dataGeneration;
    if (_lastRepoGen != gen) {
      _lastRepoGen = gen;
      _compute(widget.stations);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: AppScrollPhysics.list(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(context.loc('dip_distribution'),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: Colors.grey,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(9, (i) {
              final h = (_maxDipCount > 0) ? (_dipCounts[i] / _maxDipCount) * 150 : 0.0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${_dipCounts[i]}',
                        style: const TextStyle(fontSize: 9, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: max(2, h),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.7),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${i * 10}-${(i + 1) * 10}°',
                        style: const TextStyle(fontSize: 7, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 32),
        Text(context.loc('trend_analysis'),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: Colors.grey,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildTrendInsight(context),
      ],
    );
  }

  Widget _buildTrendInsight(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc('auto_recommendation'),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue)),
                    Text(
                      _stats.isReliable
                          ? GeoFieldStrings.of(context)!
                              .trend_recommend_good(_projToCardinal(_avgStrike))
                          : context.loc('trend_recommend_poor'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _insightRow(context.loc('trend_orientation'),
              '${_avgStrike.toStringAsFixed(1)}° (${_projToCardinal(_avgStrike)})'),
          _insightRow(
              context.loc('trend_density'), _stats.kappa.isNaN ? '—' : _stats.kappa.toStringAsFixed(1)),
          _insightRow(context.loc('trend_reliability'),
              _stats.alpha95.isNaN ? '—' : '±${_stats.alpha95.toStringAsFixed(1)}°'),
        ],
      ),
    );
  }

  Widget _insightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent)),
        ],
      ),
    );
  }

  String _projToCardinal(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'SH (North)';
    if (deg >= 22.5 && deg < 67.5) return 'SH-SH (N-E)';
    if (deg >= 67.5 && deg < 112.5) return 'SH (East)';
    if (deg >= 112.5 && deg < 157.5) return 'J-SH (S-E)';
    if (deg >= 157.5 && deg < 202.5) return 'J (South)';
    if (deg >= 202.5 && deg < 247.5) return 'J-G\' (S-W)';
    if (deg >= 247.5 && deg < 292.5) return 'G\' (West)';
    return 'SH-G\' (N-W)';
  }
}
