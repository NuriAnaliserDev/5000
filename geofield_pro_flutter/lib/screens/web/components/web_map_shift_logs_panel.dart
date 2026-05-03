import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_strings.dart';

class WebMapShiftLogsPanel extends StatelessWidget {
  final Stream<QuerySnapshot>? shiftsStream;
  final Color surfaceColor;
  final MapController mapController;

  const WebMapShiftLogsPanel({
    super.key,
    required this.shiftsStream,
    required this.surfaceColor,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Smena Jurnali (Bugun)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final stream = shiftsStream;
                if (stream == null) {
                  final s = GeoFieldStrings.of(context);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        s?.firebase_local_only_banner ??
                            'Firebase ishlamayapti — smena jurnali mavjud emas.',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.redAccent),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('Bugungi smenalar yo\'q',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final author = data['authorName'] ?? 'Noma\'lum';
                        final role = data['authorRole'] ?? '';
                        final dist =
                            (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
                        final startTimeStr = data['startTime'];
                        final startTime = startTimeStr != null
                            ? DateTime.parse(startTimeStr).toLocal()
                            : null;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          title: Text(author,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role, style: const TextStyle(fontSize: 11)),
                              Text(
                                '${(dist / 1000).toStringAsFixed(2)} km  |  ${startTime != null ? "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}" : "N/A"}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.blue),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.center_focus_strong,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              final pts = data['points'] as List?;
                              if (pts != null && pts.isNotEmpty) {
                                final last = pts.last;
                                mapController.move(
                                    LatLng(last['lat'], last['lng']), 15);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
