import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DiagnosticService {
  static final DiagnosticService instance = DiagnosticService._();
  DiagnosticService._();

  File? _logFile;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/diagnostics.log');

      // Agar fayl juda katta bo'lib ketgan bo'lsa (5MB), tozalaymiz
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > 5 * 1024 * 1024) {
          final lines = await _logFile!.readAsLines();
          // Oxirgi 1000 qatorni saqlab qolamiz (Log rotation)
          if (lines.length > 1000) {
            await _logFile!
                .writeAsString(lines.sublist(lines.length - 1000).join('\n'));
          } else {
            await _logFile!.delete();
          }
        }
      }

      await log('=== SESSION STARTED ===', tag: 'SYSTEM');
    } catch (e) {
      debugPrint('DiagnosticService init failed: $e');
    }
  }

  Future<void> log(String message, {String? tag}) async {
    final timestamp = _formatter.format(DateTime.now());
    final tagStr = tag != null ? '[$tag] ' : '';
    final line = '$timestamp $tagStr$message\n';

    if (kDebugMode) {
      // debugPrint ishlatmaymiz, chunki u ham log yozishi mumkin
      print('DIAGNOSTIC: $line');
    }

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(line, mode: FileMode.append, flush: true);
      }
    } catch (e) {
      // Jimgina o'tkazib yuboramiz
    }
  }

  Future<String> getLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return 'Loglar topilmadi.';
  }

  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      await init();
    }
  }

  Future<File?> getLogFile() async => _logFile;
}
