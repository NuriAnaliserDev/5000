/// Firebase AI / Vertex xatolaridan foydalanuvchiga tushunarli xabar va konsol URL.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Agar [raw] matn Vertex/Firebase AI API o‘chiq ekanini bildirsa, `true`.
bool isVertexAiDisabledError(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final l = raw.toLowerCase();
  return l.contains('firebasevertexai') ||
      l.contains('firebase ai logic') ||
      l.contains('aiplatform') ||
      l.contains('service_disabled') ||
      l.contains('api has not been enabled') ||
      (l.contains('vertex') && l.contains('not been')) ||
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

/// [Vertex AI API] ni yoqish sahifasi — Firebase bilan bir xil Google Cloud loyihasi.
/// https://cloud.google.com/vertex-ai/docs/start/client-libraries#before-you-begin
Uri fallbackVertexApiEnableUri() {
  try {
    final id = Firebase.app().options.projectId;
    if (id.isNotEmpty) {
      return Uri.parse(
        'https://console.cloud.google.com/apis/library/aiplatform.googleapis.com?project=$id',
      );
    }
  } catch (e) {
    debugPrint('fallbackVertexApiEnableUri: $e');
  }
  return Uri.parse(
    'https://console.cloud.google.com/apis/library/aiplatform.googleapis.com',
  );
}

/// Konsol havolasini ochadi: avvalo xatodan URL, bo‘lmasa Vertex AI API / loyiha.
Future<bool> openVertexErrorLink(String rawError) async {
  final u = parseGoogleCloudUrlFromError(rawError) ?? fallbackVertexApiEnableUri();
  try {
    if (await canLaunchUrl(u)) {
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('openVertexErrorLink: $e');
  }
  return false;
}
