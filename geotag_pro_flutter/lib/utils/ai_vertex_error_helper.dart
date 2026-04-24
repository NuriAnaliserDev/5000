/// Firebase AI / Vertex xatolaridan foydalanuvchiga tushunarli xabar va konsol URL.
library;

import 'package:url_launcher/url_launcher.dart';

/// Agar [raw] matn Vertex/Firebase AI API o‘chiq ekanini bildirsa, `true`.
bool isVertexAiDisabledError(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final l = raw.toLowerCase();
  return l.contains('firebasevertexai') ||
      l.contains('firebase ai logic') ||
      (l.contains('has not been used') && l.contains('disabled')) ||
      (l.contains('has not been used') && l.contains('api'));
}

/// Konsol/jurnal matnidan birinchi Google Cloud/ Developers havolasini oladi.
Uri? parseGoogleCloudUrlFromError(String raw) {
  final m = RegExp(
    r'https://console\.(developers\.google|cloud\.google)\.com[^\s\)\"]+',
  ).firstMatch(raw);
  if (m == null) return null;
  var s = m.group(0);
  if (s == null) return null;
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  if (s.endsWith(',')) s = s.substring(0, s.length - 1);
  return Uri.tryParse(s);
}

Future<void> openVertexErrorLink(String rawError) async {
  final u = parseGoogleCloudUrlFromError(rawError);
  if (u == null) return;
  if (await canLaunchUrl(u)) {
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }
}
