import 'dart:convert';
import 'dart:io';

import '../core/diagnostics/production_diagnostics.dart';
import 'settings_controller.dart';

/// Bir capture uchun inflight belgisi va muvaffaqiyatsizlikda yetim fayl loglari.
/// “Repository qayta yozilmaydi” — faqat yordamchi.
abstract final class FieldCaptureAtomic {
  static void markInflight(
    SettingsController settings, {
    required String captureId,
    required int startedMs,
    required String sessionId,
    required String photoPath,
  }) {
    settings.setInflightFieldCaptureJson(jsonEncode({
      'capture_id': captureId,
      'started_ms': startedMs,
      'session': sessionId,
      'photo_path': photoPath,
    }));
  }

  static void clearInflight(SettingsController settings) {
    settings.setInflightFieldCaptureJson(null);
  }

  static Future<void> logFailedCapture(String? photoPath, Object error) async {
    if (photoPath == null || photoPath.isEmpty) {
      return;
    }
    try {
      final f = File(photoPath);
      final exists = await f.exists();
      final len = exists ? await f.length() : 0;
      await ProductionDiagnostics.storage(
        'recovery_orphan_photo_candidate',
        data: {
          'tail': photoPath.contains(Platform.pathSeparator)
              ? photoPath.split(Platform.pathSeparator).last
              : photoPath,
          'exists': exists,
          'bytes': len,
          'error': error.toString(),
        },
      );
    } catch (_) {}
  }
}
