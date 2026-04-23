import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/station.dart';
import '../../../services/station_repository.dart';
import '../../../utils/app_card.dart';
import '../../../utils/geology_utils.dart';
import '../../../utils/app_localizations.dart';

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
  int? _cachedLen;
  FisherStats? _stats;

  void _maybeRecompute(List<Station> stations) {
    final n = stations.length;
    if (_cachedLen == n && _stats != null) {
      return;
    }
    _cachedLen = n;
    final strikes = stations.map((s) => s.strike).toList();
    _stats = GeologyUtils.fisherStats(strikes);
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationRepository>().stations;
    _maybeRecompute(stations);
    if (_stats == null) {
      return const SizedBox.shrink();
    }
    final stats = _stats!;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc('fisher_reliability'),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                stats.alpha95.isNaN
                    ? '—'
                    : '±${stats.alpha95.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: stats.isReliable ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              const Text('α₉₅', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text(
            stats.isReliable
                ? context.loc('fisher_stable')
                : context.loc('fisher_dispersion'),
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: stats.isReliable ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
  }
}
