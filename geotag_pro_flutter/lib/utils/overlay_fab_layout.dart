import 'package:flutter/material.dart';

/// Xarita va kamera suzuvchi tugmalarining default [Offset] / [Size] qiymatlari.
/// Bitta joyda saqlanadi — UX o‘zgartirishda shu faylni yangilang.
abstract final class OverlayFabLayout {
  // ─── Xarita (screen: map) ───
  static const Offset mapStructure = Offset(8, -200);
  static const Size mapStructureSize = Size(52, 52);

  static const Offset mapProTools = Offset(12, -96);
  static const Size mapProToolsSize = Size(56, 56);

  static const Offset mapSos = Offset(-12, -40);
  static const Size mapSosSize = Size(100, 200);

  static const Offset mapTrack = Offset(-12, -168);
  static const Size mapTrackSize = Size(56, 56);

  static const Offset mapMyLocation = Offset(-12, -248);
  static const Size mapMyLocationSize = Size(48, 48);

  static const Offset mapFollowGps = Offset(-12, -318);
  static const Size mapFollowGpsSize = Size(48, 48);

  static const double mapSosDragHandleWidth = 22;

  // ─── Kamera (screen: camera) ───
  static const Offset cameraSidePanel = Offset(-82, 170);
  static const Size cameraSidePanelSize = Size(70, 300);

  /// Pastki panel: kenglik [MediaQuery] dan olinadi.
  static const Offset cameraBottomPanel = Offset(0, -160);
  static const double cameraBottomPanelHeight = 150;
}
