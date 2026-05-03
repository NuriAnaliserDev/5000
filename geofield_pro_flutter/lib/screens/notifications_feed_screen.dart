import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app_router.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../utils/firebase_ready.dart';

/// Dashboarddan yoki admin tomondan [geofield_broadcasts] ga yoziladigan ommaviy e'lonlar.
///
/// Firestore qoidalari: masalan
/// `match /geofield_broadcasts/{id} { allow read: if request.auth != null; allow write: if false; }`
/// (yozish faqat admin konsol yoki bulut funksiya orqali).
class NotificationsFeedScreen extends StatefulWidget {
  const NotificationsFeedScreen({super.key});

  @override
  State<NotificationsFeedScreen> createState() =>
      _NotificationsFeedScreenState();
}

class _NotificationsFeedScreenState extends State<NotificationsFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surf = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        backgroundColor: surf,
        elevation: 0,
        title: Text(
          s.notifications_screen_title,
          style:
              const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRouter.messages),
            icon: const Icon(Icons.forum_outlined, size: 20),
            label: Text(s.notifications_open_chats),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final fs = firestoreOrNull;
          if (fs == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  s.firebase_local_only_banner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            );
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.collection('geofield_broadcasts').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              docs.sort((a, b) {
                final ta = a.data()['createdAt'];
                final tb = b.data()['createdAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.notifications_empty_hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.4, fontSize: 14),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final title = (d['title'] ?? d['subject'] ?? '—') as String;
                  final body = (d['body'] ?? d['message'] ?? '') as String;
                  final author =
                      (d['authorName'] ?? d['author'] ?? '') as String;
                  String timeStr = '';
                  final t = d['createdAt'];
                  if (t is Timestamp) {
                    timeStr = DateFormat.yMMMd().add_Hm().format(t.toDate());
                  }
                  return Material(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(body,
                                style:
                                    const TextStyle(height: 1.3, fontSize: 13)),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (author.isNotEmpty) author,
                              if (timeStr.isNotEmpty) timeStr
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
