import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../core/error/error_logger.dart';

/// AI chaqiriqlarni kunlik kvota bilan cheklaydi.
///
/// Hive box: `ai_quota`, key: `YYYY-MM-DD:<uid>` → int (bugungi soni).
class AiRateLimiter {
  AiRateLimiter._();

  static const String boxName = 'ai_quota';
  static const int defaultDailyLimit = 20;
  static const int minIntervalSeconds = 10;

  static Box<int>? _box;
  static Box<String>? _timeBox;

  static Future<Box<int>> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    try {
      _box = await Hive.openBox<int>(boxName);
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'AiRateLimiter.open ai_quota');
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      _box = await Hive.openBox<int>(boxName);
    }
    return _box!;
  }

  static Future<Box<String>> _openTimeBox() async {
    if (_timeBox != null && _timeBox!.isOpen) return _timeBox!;
    const timeName = 'ai_last_request';
    try {
      _timeBox = await Hive.openBox<String>(timeName);
    } catch (e, st) {
      ErrorLogger.record(e, st, customMessage: 'AiRateLimiter.open ai_last_request');
      try {
        await Hive.deleteBoxFromDisk(timeName);
      } catch (_) {}
      _timeBox = await Hive.openBox<String>(timeName);
    }
    return _timeBox!;
  }

  static String _todayKey(String uid) {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d:$uid';
  }

  /// Hozirgacha bugungi soni.
  static Future<int> todayCount(String uid) async {
    final box = await _openBox();
    return box.get(_todayKey(uid), defaultValue: 0) ?? 0;
  }

  /// Kvota oshib ketsa [QuotaExceededException] tashlaydi. 
  /// Interval buzilsa [RateLimitException] tashlaydi.
  /// Aks holda +1 va timestamp yangilanadi.
  static Future<void> consume(String uid, {int? limit}) async {
    // 1. Interval tekshiruvi
    final timeBox = await _openTimeBox();
    final lastTimeStr = timeBox.get(uid);
    if (lastTimeStr != null) {
      final lastTime = DateTime.parse(lastTimeStr);
      final diff = DateTime.now().difference(lastTime).inSeconds;
      if (diff < minIntervalSeconds) {
        throw RateLimitException(remaining: minIntervalSeconds - diff);
      }
    }

    // 2. Kunlik limit tekshiruvi
    final l = limit ?? defaultDailyLimit;
    final box = await _openBox();
    final key = _todayKey(uid);
    final cur = box.get(key, defaultValue: 0) ?? 0;
    if (cur >= l) {
      throw QuotaExceededException(current: cur, limit: l);
    }

    // Saqlash
    await box.put(key, cur + 1);
    await timeBox.put(uid, DateTime.now().toIso8601String());
  }

  /// Admin/debug: bugungi kvotani nollash.
  static Future<void> resetToday(String uid) async {
    try {
      final box = await _openBox();
      await box.delete(_todayKey(uid));
    } catch (e) {
      debugPrint('AiRateLimiter.resetToday error: $e');
    }
  }
}

class QuotaExceededException implements Exception {
  final int current;
  final int limit;
  QuotaExceededException({required this.current, required this.limit});

  @override
  String toString() =>
      'AI kundalik chegarasi oshib ketdi ($current/$limit). Ertaga qayta urining yoki admin bilan bog‘laning.';
}

class RateLimitException implements Exception {
  final int remaining;
  RateLimitException({required this.remaining});

  @override
  String toString() => 'Iltimos, keyingi so\'rov uchun $remaining soniya kuting.';
}
