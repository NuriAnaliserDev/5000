import 'package:flutter/material.dart';

enum StatusLevel { good, warn, danger, info }

class StatusSemantics {
  static const Color good = Colors.greenAccent;
  static const Color warn = Colors.orangeAccent;
  static const Color danger = Colors.redAccent;
  static const Color info = Color(0xFF42A5F5);

  static Color colorFor(StatusLevel level) {
    switch (level) {
      case StatusLevel.good:
        return good;
      case StatusLevel.warn:
        return warn;
      case StatusLevel.danger:
        return danger;
      case StatusLevel.info:
        return info;
    }
  }
}
