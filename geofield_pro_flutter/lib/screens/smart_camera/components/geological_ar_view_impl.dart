import 'dart:async';
import 'dart:io';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

bool geologicalArSupportedPlatform() =>
    Platform.isAndroid || Platform.isIOS;

/// AR sessiyasidan surat fayl yo‘liga yozish.
class GeologicalArSessionController {
  ARSessionManager? _session;

  void bindSession(ARSessionManager? session) {
    _session = session;
  }

  Future<String?> captureToTempFile() async {
    final sm = _session;
    if (sm == null) {
      return null;
    }
    try {
      final img = await sm.snapshot();
      if (img is! MemoryImage) {
        return null;
      }
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}${Platform.pathSeparator}geofield_ar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await f.writeAsBytes(img.bytes);
      return f.path;
    } catch (e, st) {
      debugPrint('AR capture: $e\n$st');
      return null;
    }
  }
}

/// Geologik kamera — ARCore / ARKit orqali kuzatuvchi tekislik va oldinda qatlam belgisi.
class GeologicalArView extends StatefulWidget {
  const GeologicalArView({
    super.key,
    required this.onControllerReady,
    required this.onDisposed,
  });

  final ValueChanged<GeologicalArSessionController> onControllerReady;
  final VoidCallback onDisposed;

  @override
  State<GeologicalArView> createState() => _GeologicalArViewState();
}

class _GeologicalArViewState extends State<GeologicalArView> {
  final GeologicalArSessionController _controller = GeologicalArSessionController();
  ARSessionManager? _arSession;
  ARNode? _beddingNode;
  Timer? _ticker;
  bool _reportedReady = false;

  /// Yengil GLB (bir marta tarmoqdan; keyin kesh). Khronos namunasi.
  static const _kBeddingModelUri =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Box/glTF-Binary/Box.glb';

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.bindSession(null);
    unawaited(_arSession?.dispose());
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _onARViewCreated(
    ARSessionManager session,
    ARObjectManager objects,
    ARAnchorManager _,
    ARLocationManager __,
  ) async {
    _arSession = session;
    _controller.bindSession(session);

    await session.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: false,
      handlePans: false,
      handleRotation: false,
    );
    await objects.onInitialize();

    final node = ARNode(
      type: NodeType.webGLB,
      uri: _kBeddingModelUri,
      scale: Vector3(0.42, 0.42, 0.03),
      transformation: Matrix4.identity(),
    );
    _beddingNode = node;
    await objects.addNode(node);

    if (!mounted) {
      return;
    }
    if (!_reportedReady) {
      _reportedReady = true;
      widget.onControllerReady(_controller);
    }

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 90), (_) {
      unawaited(_syncBeddingPlane());
    });
    unawaited(_syncBeddingPlane());
  }

  Future<void> _syncBeddingPlane() async {
    final node = _beddingNode;
    final session = _arSession;
    if (node == null || session == null || !mounted) {
      return;
    }
    final cam = await session.getCameraPose();
    if (cam == null) {
      return;
    }
    const d = 1.35;
    final R = cam.getRotation();
    final camPos = cam.getTranslation();
    final forward = (R * Vector3(0.0, 0.0, -1.0)).normalized();
    final center = camPos + forward * d;
    node.transform = Matrix4.compose(
      center,
      Quaternion.fromRotation(R),
      Vector3(0.42, 0.42, 0.03),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!geologicalArSupportedPlatform()) {
      return const ColoredBox(color: Colors.black);
    }
    return ARView(
      onARViewCreated: _onARViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }
}
