import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/sync_conflict.dart';
import '../hive_db.dart';

/// Sinxronizatsiya paytida yuzaga kelgan konfliktlarni boshqarish xizmati.
/// Ma'lumotlarni alohida xavfsiz navbatda saqlaydi va UI uchun stream beradi.
class ConflictQueueService extends ChangeNotifier {
  ConflictQueueService()
      : _conflictBox = Hive.box<SyncConflict>(HiveDb.syncConflictsBox);

  final Box<SyncConflict> _conflictBox;

  List<SyncConflict> get conflicts => _conflictBox.values.toList();

  ValueListenable<Box<SyncConflict>> get listenable => _conflictBox.listenable();

  /// Yangi konflikt qo'shish. SyncProcessor buni chaqiradi.
  Future<void> addConflict(SyncConflict conflict) async {
    // Agar xuddi shu entityId uchun konflikt bo'lsa, uni yangilaymiz
    final existingKey = _conflictBox.keys.firstWhere(
      (k) => _conflictBox.get(k)?.entityId == conflict.entityId,
      orElse: () => null,
    );

    if (existingKey != null) {
      await _conflictBox.put(existingKey, conflict);
    } else {
      await _conflictBox.put(conflict.id, conflict);
    }
    notifyListeners();
  }

  /// Konflikt hal qilingandan so'ng navbatdan o'chirish.
  Future<void> resolveConflict(String conflictId) async {
    await _conflictBox.delete(conflictId);
    notifyListeners();
  }

  /// Barcha konfliktlarni o'chirish (masalan, loyiha o'chirilganda).
  Future<void> clearAll() async {
    await _conflictBox.clear();
    notifyListeners();
  }

  int get conflictCount => _conflictBox.length;
}
