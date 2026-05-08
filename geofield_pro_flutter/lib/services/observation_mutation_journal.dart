import 'package:hive/hive.dart';

import '../models/observation_mutation_event.dart';
import 'hive_db.dart';

/// Yengil append-only jurnal (so‘nggi ~300 yozuv).
abstract final class ObservationMutationJournal {
  static const _key = 'observationMutationJournalV1';
  static const int _maxEntries = 300;

  static void append(ObservationMutationEvent event) {
    try {
      final box = Hive.box(HiveDb.settingsBox);
      final raw = box.get(_key);
      final list = <String>[
        if (raw is List) ...raw.map((e) => e.toString()),
      ];
      list.add(event.encodeLine());
      while (list.length > _maxEntries) {
        list.removeAt(0);
      }
      box.put(_key, list);
    } catch (_) {}
  }

  static List<String> readLines() {
    try {
      final box = Hive.box(HiveDb.settingsBox);
      final raw = box.get(_key);
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }
}
