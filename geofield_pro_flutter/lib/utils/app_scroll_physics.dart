import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bitta joydan scroll physics — reja: iOS = bounce, Android = clamp, web = bounce.
class AppScrollPhysics {
  AppScrollPhysics._();

  static ScrollPhysics list() {
    if (kIsWeb) {
      return const BouncingScrollPhysics();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      default:
        return const ClampingScrollPhysics();
    }
  }
}
