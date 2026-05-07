import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'hive_db.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }
  ThemeMode _mode = ThemeMode.system;
  static const _key = 'themeMode';

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _save();
    notifyListeners();
  }

  void _load() {
    try {
      final box = Hive.box(HiveDb.settingsBox);
      final v = box.get(_key) as int?;
      if (v != null && v >= 0 && v <= 2) {
        _mode = ThemeMode.values[v];
      }
    } catch (e) {
      debugPrint('Theme load failed: $e');
    }
  }

  void _save() {
    try {
      Hive.box(HiveDb.settingsBox).put(_key, _mode.index);
    } catch (e) {
      debugPrint('Theme save failed: $e');
    }
  }
}
