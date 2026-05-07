import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'diagnostic_domain.dart';
import 'log_channels.dart';
import 'memory_snapshot.dart';

class DiagnosticService {
  static final DiagnosticService instance = DiagnosticService._();
  DiagnosticService._();

  File? _logFile;
  File? _structuredLogFile;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  bool _ready = false;
  final List<String> _pendingStructuredLines = [];
  static const int _maxPending = 400;

  bool get isReady => _ready;

  /// Matnli log — har doim [BOOT] kabi prefix bilan (FREEZE: log strategy).
  Future<void> logPrefixed(
    DiagLogChannel channel,
    String message, {
    String? tag,
  }) {
    return log('${channel.prefix} $message', tag: tag ?? channel.name);
  }

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/diagnostics.log');
      _structuredLogFile = File('${directory.path}/diagnostics_structured.jsonl');

      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > 5 * 1024 * 1024) {
          final lines = await _logFile!.readAsLines();
          if (lines.length > 1000) {
            await _logFile!
                .writeAsString(lines.sublist(lines.length - 1000).join('\n'));
          } else {
            await _logFile!.delete();
          }
        }
      }

      if (await _structuredLogFile!.exists()) {
        final sSize = await _structuredLogFile!.length();
        if (sSize > 5 * 1024 * 1024) {
          await _structuredLogFile!.delete();
        }
      }

      await logPrefixed(DiagLogChannel.boot, '=== SESSION STARTED ===');

      for (final line in _pendingStructuredLines) {
        await _appendStructuredLine(line);
      }
      _pendingStructuredLines.clear();
      _ready = true;

      final bootMem = memoryPayloadForDiagnostics();
      await logStructured(
        domain: DiagnosticDomain.startup,
        event: 'diagnostic_service_ready',
        data: bootMem != null ? {'memory': bootMem} : null,
      );
    } catch (e) {
      debugPrint('DiagnosticService init failed: $e');
    }
  }

  String _encodeStructuredLine({
    required DiagnosticDomain domain,
    required String event,
    String? phase,
    required Map<String, Object?> payload,
  }) {
    return jsonEncode({
      'ts': DateTime.now().toUtc().toIso8601String(),
      'domain': domain.name,
      'event': event,
      if (phase != null) 'phase': phase,
      'payload': payload,
    });
  }

  /// Fayl ochilguncha navbat — startup/hot-restart uchun.
  void enqueueStructured({
    required DiagnosticDomain domain,
    required String event,
    String? phase,
    Map<String, Object?>? payload,
  }) {
    final line = _encodeStructuredLine(
      domain: domain,
      event: event,
      phase: phase,
      payload: payload ?? const {},
    );
    if (_ready) {
      unawaited(_appendStructuredLine(line));
    } else {
      if (_pendingStructuredLines.length < _maxPending) {
        _pendingStructuredLines.add(line);
      }
    }
  }

  Future<void> logStructured({
    required DiagnosticDomain domain,
    required String event,
    String? phase,
    Map<String, Object?>? data,
    bool includeMemory = false,
  }) async {
    final payload = <String, Object?>{
      if (data != null) ...data,
    };
    if (includeMemory) {
      final m = memoryPayloadForDiagnostics();
      if (m != null) {
        payload['memory'] = m;
      }
    }
    final line = _encodeStructuredLine(
      domain: domain,
      event: event,
      phase: phase,
      payload: payload,
    );
    if (!_ready) {
      if (_pendingStructuredLines.length < _maxPending) {
        _pendingStructuredLines.add(line);
      }
      return;
    }
    await _appendStructuredLine(line);
  }

  Future<void> _appendStructuredLine(String line) async {
    try {
      if (_structuredLogFile != null) {
        await _structuredLogFile!.writeAsString(
          '$line\n',
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (_) {}
    if (kDebugMode) {
      // ignore: avoid_print
      print('DIAG_JSON: $line');
    }
  }

  Future<void> log(String message, {String? tag}) async {
    final timestamp = _formatter.format(DateTime.now());
    final tagStr = tag != null ? '[$tag] ' : '';
    final line = '$timestamp $tagStr$message\n';

    if (kDebugMode) {
      // ignore: avoid_print
      print('DIAGNOSTIC: $line');
    }

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(line, mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }

  Future<String> getLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return 'Loglar topilmadi.';
  }

  Future<String> getStructuredLogs() async {
    if (_structuredLogFile != null && await _structuredLogFile!.exists()) {
      return await _structuredLogFile!.readAsString();
    }
    return '';
  }

  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
    }
    if (_structuredLogFile != null && await _structuredLogFile!.exists()) {
      await _structuredLogFile!.delete();
    }
    await init();
  }

  Future<File?> getLogFile() async => _logFile;

  Future<File?> getStructuredLogFile() async => _structuredLogFile;
}
