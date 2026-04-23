import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/track_service.dart';
import '../../utils/app_card.dart';
import '../../utils/app_localizations.dart';

class DashboardSessionBox extends StatefulWidget {
  final bool isDark;

  const DashboardSessionBox({super.key, required this.isDark});

  @override
  State<DashboardSessionBox> createState() => _DashboardSessionBoxState();
}

class _DashboardSessionBoxState extends State<DashboardSessionBox> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<TrackService>().isTracking) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final trackSvc = context.watch<TrackService>();
    final track = trackSvc.currentTrack;
    final isTracking = trackSvc.isTracking;
    final hasActiveTrack = isTracking && track != null;

    return AppCard(
      height: 160,
      opacity: widget.isDark ? 0.12 : 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: isTracking ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(
                (context.loc('session')).toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              hasActiveTrack ? _formatDuration(DateTime.now().difference(track.startTime)) : '00:00:00',
              key: ValueKey(
                hasActiveTrack ? (DateTime.now().difference(track.startTime).inSeconds / 10).floor() : 0,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${((track?.distanceMeters ?? 0) / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${track?.stationsCount ?? 0} st',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
