import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../utils/app_card.dart';
import '../../../models/track_data.dart';
import '../../../utils/app_localizations.dart';

class MapLiveTrackStats extends StatelessWidget {
  final TrackData track;

  const MapLiveTrackStats({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 70,
      left: 16,
      right: 16,
      child: AppCard(
        opacity: 0.35,
        blur: 15,
        borderRadius: 24,
        baseColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.timer, color: Colors.greenAccent, size: 20),
                 const SizedBox(height: 4),
                 StreamBuilder(
                   stream: Stream.periodic(const Duration(seconds: 1)),
                   builder: (context, snapshot) {
                     final dur = DateTime.now().difference(track.startTime);
                     final hours = dur.inHours.toString().padLeft(2, '0');
                     final mins = (dur.inMinutes % 60).toString().padLeft(2, '0');
                     final secs = (dur.inSeconds % 60).toString().padLeft(2, '0');
                     return Text(
                       '$hours:$mins:$secs',
                       style: const TextStyle(
                         color: Colors.white, 
                         fontWeight: FontWeight.bold, 
                         fontSize: 16, 
                         fontFeatures: [FontFeature.tabularFigures()]
                       ),
                     );
                   }
                 ),
                 Text(
                   context.loc('time_label'), 
                   style: const TextStyle(color: Colors.grey, fontSize: 8, letterSpacing: 1)
                 ),
               ],
             ),
             Container(width: 1, height: 40, color: Colors.white12),
             Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.social_distance, color: Colors.greenAccent, size: 20),
                 const SizedBox(height: 4),
                 Text(
                   '${(track.distanceMeters / 1000).toStringAsFixed(2)} km',
                   style: const TextStyle(
                     color: Colors.white, 
                     fontWeight: FontWeight.bold, 
                     fontSize: 16, 
                     fontFeatures: [FontFeature.tabularFigures()]
                   ),
                 ),
                 Text(
                   context.loc('distance_label'), 
                   style: const TextStyle(color: Colors.grey, fontSize: 8, letterSpacing: 1)
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}
