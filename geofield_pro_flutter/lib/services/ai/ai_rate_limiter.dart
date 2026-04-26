import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// AI chaqiriqlarni kunlik kvota bilan cheklaydi.
///
/// Hive box: `ai_quota`, key: `YYYY-MM-DD:<uid>` → int (bugungi soni).
class AiRateLimiter {
  AiRateLimiter._();

  static const String boxName = 'ai_quota';
  static const int defaultDailyLimit = 20;

  static Box<int>? _box;

  static Future<Box<int>> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<int>(boxName);
    return _box!;
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

  /// Kvota oshib ketsa [QuotaExceededException] tashlaydi. Aks holda +1.
  static Future<void> consume(String uid, {int? limit}) async {
    final l = limit ?? defaultDailyLimit;
    final box = await _openBox();
    final key = _todayKey(uid);
    final cur = box.get(key, defaultValue: 0) ?? 0;
    if (cur >= l) {
      throw QuotaExceededException(current: cur, limit: l);
    }
    await box.put(key, cur + 1);
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
