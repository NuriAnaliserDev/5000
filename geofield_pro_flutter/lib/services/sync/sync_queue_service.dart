import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:synchronized/synchronized.dart';
import '../../models/sync_item.dart';
import '../hive_db.dart';

class SyncQueueService extends ChangeNotifier {
  late final Box<SyncItem> _box;
  final _lock = Lock();

  SyncQueueService() {
    _box = Hive.box<SyncItem>(HiveDb.syncQueueBox);
  }

  /// Navbatga yangi element qo'shish (Deduplication / Coalescing bilan)
  Future<void> addItem(SyncItem newItem) async {
    await _lock.synchronized(() async {
      // Pending holatdagi ushbu entity uchun mavjud itemni qidirish
      final existingKey = _findExistingPendingKey(newItem.entityId, newItem.entityType);

      if (existingKey != null) {
        final existingItem = _box.get(existingKey)!;
        final merged = _merge(existingItem, newItem);

        if (merged == null) {
          // Cancel out (masalan: Create + Delete)
          await _box.delete(existingKey);
        } else {
          // O'zgartirish (Update + Update yoki Create + Update)
          await _box.put(existingKey, merged);
        }
      } else {
        // Yangi navbat elementi
        await _box.add(newItem);
      }
      notifyListeners();
    });
  }

  /// Coalescing Logikasi
  SyncItem? _merge(SyncItem oldItem, SyncItem newItem) {
    // 1. Agar yangi amal DELETE bo'lsa
    if (newItem.operation == SyncOperation.delete) {
      // Agar hali serverda yaratilmagan bo'lsa (pending create), ikkalasini ham o'chiramiz
      if (oldItem.operation == SyncOperation.create) return null;
      // Aks holda delete amalini saqlaymiz (update'ni o'chirib yuboradi)
      return newItem; 
    }

    // 2. Agar mavjud amal CREATE bo'lsa va yangisi UPDATE bo'lsa
    if (oldItem.operation == SyncOperation.create && newItem.operation == SyncOperation.update) {
      // CREATE amalini saqlab qolamiz, lekin payloadni eng yangisiga yangilaymiz
      return oldItem.copyWith(
        payload: newItem.payload,
        version: newItem.version,
        createdAt: newItem.createdAt,
      );
    }

    // 3. Agar ikkalasi ham UPDATE bo'lsa, shunchaki yangisiga almashtiramiz
    if (oldItem.operation == SyncOperation.update && newItem.operation == SyncOperation.update) {
      return newItem;
    }

    // Default: yangi amalni saqlash
    return newItem;
  }

  dynamic _findExistingPendingKey(String entityId, String entityType) {
    try {
      return _box.keys.firstWhere((key) {
        final item = _box.get(key);
        return item != null &&
            item.entityId == entityId &&
            item.entityType == entityType &&
            item.status == SyncStatus.pending;
      });
    } catch (_) {
      return null;
    }
  }

  List<SyncItem> get pendingItems => _box.values
      .where((item) => item.status == SyncStatus.pending)
      .toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));

  /// Monotonik ketma-ketlik uchun keyingi raqamni olish
  int getNextSequence() {
    if (_box.isEmpty) return 1;
    final maxSeq = _box.values.fold<int>(0, (max, item) => item.sequence > max ? item.sequence : max);
    return maxSeq + 1;
  }

  /// App crash bo'lganda processingda qolib ketganlarni pendingga qaytaradi
  Future<void> resetProcessingItems() async {
    await _lock.synchronized(() async {
      final stuckItems = _box.values.where((item) => item.status == SyncStatus.processing).toList();
      for (var item in stuckItems) {
        item.status = SyncStatus.pending;
        await item.save();
      }
      if (stuckItems.isNotEmpty) notifyListeners();
    });
  }

  /// Element statusini yangilash
  Future<void> updateItemStatus(SyncItem item, SyncStatus status) async {
    await _lock.synchronized(() async {
      item.status = status;
      await item.save();
      notifyListeners();
    });
  }

  /// Elementni navbatdan o'chirish (Muvaffaqiyatli sync bo'lganda)
  Future<void> removeItem(SyncItem item) async {
    await _lock.synchronized(() async {
      await item.delete();
      notifyListeners();
    });
  }
}
