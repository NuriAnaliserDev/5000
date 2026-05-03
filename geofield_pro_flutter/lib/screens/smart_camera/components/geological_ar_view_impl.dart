import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:geofield_pro_flutter/utils/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

bool geologicalArSupportedPlatform() => Platform.isAndroid || Platform.isIOS;

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
    final dir = await getTemporaryDirectory();
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final img = await sm.snapshot();
        if (img is! MemoryImage) {
          debugPrint('AR capture: snapshot returned ${img.runtimeType}');
        } else {
          final bytes = img.bytes;
          if (bytes.isEmpty) {
            debugPrint('AR capture: empty bytes');
          } else {
            final ext = _arSnapshotFileExtension(bytes);
            final f = File(
              '${dir.path}${Platform.pathSeparator}geofield_ar_${DateTime.now().millisecondsSinceEpoch}.$ext',
            );
            await f.writeAsBytes(bytes);
            return f.path;
          }
        }
      } catch (e, st) {
        debugPrint('AR capture attempt $attempt: $e\n$st');
      }
      await Future<void>.delayed(Duration(milliseconds: 120 + attempt * 80));
    }
    return null;
  }

  static String _arSnapshotFileExtension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'jpg';
  }
}

/// Geologik kamera — ARCore / ARKit: tekislikka anchor, yoki kamera oldida kuzatuv.
class GeologicalArView extends StatefulWidget {
  const GeologicalArView({
    super.key,
    required this.onControllerReady,
    required this.onDisposed,
    this.onArSessionStalled,
  });

  final ValueChanged<GeologicalArSessionController> onControllerReady;
  final VoidCallback onDisposed;

  /// ARCore/ARKit oynasi ~12s ichida [onControllerReady] bermasa chaqiriladi.
  final VoidCallback? onArSessionStalled;

  @override
  State<GeologicalArView> createState() => _GeologicalArViewState();
}

class _GeologicalArViewState extends State<GeologicalArView> {
  final GeologicalArSessionController _controller =
      GeologicalArSessionController();
  ARSessionManager? _arSession;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;
  ARNode? _beddingNode;
  ARPlaneAnchor? _placedAnchor;
  Timer? _ticker;
  Timer? _stallTimer;
  bool _reportedReady = false;

  /// Kamera bilan harakatlanuvchi rejim (anchor qo‘yilgunicha).
  bool _followCamera = true;

  static const _kBeddingModelUri =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Box/glTF-Binary/Box.glb';

  static const _kSlabScale = [0.42, 0.42, 0.03];

  ARNode _makeBeddingNode() {
    return ARNode(
      type: NodeType.webGLB,
      uri: _kBeddingModelUri,
      scale: Vector3(_kSlabScale[0], _kSlabScale[1], _kSlabScale[2]),
      transformation: Matrix4.identity(),
    );
  }

  void _startFollowCameraTicker() {
    if (!_followCamera) {
      return;
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 90), (_) {
      unawaited(_syncBeddingPlane());
    });
    unawaited(_syncBeddingPlane());
  }

  void _stopFollowCameraTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void initState() {
    super.initState();
    _stallTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || _reportedReady) {
        return;
      }
      widget.onArSessionStalled?.call();
    });
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    _stopFollowCameraTicker();
    _controller.bindSession(null);
    unawaited(_arSession?.dispose());
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _onARViewCreated(
    ARSessionManager session,
    ARObjectManager objects,
    ARAnchorManager anchorManager,
    ARLocationManager _,
  ) async {
    _arSession = session;
    _objectManager = objects;
    _anchorManager = anchorManager;
    _controller.bindSession(session);

    session.onPlaneOrPointTap = _onPlaneOrPointTap;

    await session.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: false,
      handleRotation: false,
    );
    await objects.onInitialize();

    _beddingNode = _makeBeddingNode();
    await objects.addNode(_beddingNode!);

    if (!mounted) {
      return;
    }
    if (!_reportedReady) {
      _stallTimer?.cancel();
      _stallTimer = null;
      _reportedReady = true;
      widget.onControllerReady(_controller);
    }
    setState(() {});

    _followCamera = true;
    _startFollowCameraTicker();
  }

  void _onPlaneOrPointTap(List<ARHitTestResult> hits) {
    unawaited(_handlePlaneTap(hits));
  }

  Future<void> _handlePlaneTap(List<ARHitTestResult> hits) async {
    final objects = _objectManager;
    final anchors = _anchorManager;
    final session = _arSession;
    if (objects == null || anchors == null || session == null) {
      return;
    }

    final planeHits =
        hits.where((h) => h.type == ARHitTestResultType.plane).toList();
    if (planeHits.isEmpty) {
      if (mounted) {
        session.onError(context.locRead('camera_ar_no_plane_hit'));
      }
      return;
    }

    _stopFollowCameraTicker();

    final node = _beddingNode;
    if (node != null) {
      objects.removeNode(node);
    }
    final oldAnchor = _placedAnchor;
    if (oldAnchor != null) {
      anchors.removeAnchor(oldAnchor);
    }
    _placedAnchor = null;
    _beddingNode = null;

    if (!mounted) {
      return;
    }

    final hit = planeHits.first;
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAdd = await anchors.addAnchor(anchor);
    if (didAdd != true) {
      if (mounted) {
        session.onError(context.locRead('camera_ar_anchor_failed'));
        await _restoreFollowCameraMode(objects);
      }
      return;
    }

    final anchoredNode = _makeBeddingNode();
    anchoredNode.position = Vector3.zero();
    anchoredNode.rotation = Matrix3.identity();
    final ok = await objects.addNode(anchoredNode, planeAnchor: anchor);
    if (ok != true) {
      anchors.removeAnchor(anchor);
      if (mounted) {
        session.onError(context.locRead('camera_ar_node_failed'));
        await _restoreFollowCameraMode(objects);
      }
      return;
    }

    _placedAnchor = anchor;
    _beddingNode = anchoredNode;
    _followCamera = false;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _restoreFollowCameraMode(ARObjectManager objects) async {
    _placedAnchor = null;
    _followCamera = true;
    _beddingNode = _makeBeddingNode();
    await objects.addNode(_beddingNode!);
    if (mounted) {
      _startFollowCameraTicker();
      setState(() {});
    }
  }

  Future<void> _syncBeddingPlane() async {
    if (!_followCamera) {
      return;
    }
    final node = _beddingNode;
    final arSession = _arSession;
    if (node == null || arSession == null || !mounted) {
      return;
    }
    final cam = await arSession.getCameraPose();
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
      Vector3(_kSlabScale[0], _kSlabScale[1], _kSlabScale[2]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!geologicalArSupportedPlatform()) {
      return const ColoredBox(color: Colors.black);
    }

    final showTapHint = _reportedReady && _followCamera && _arSession != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
        ),
        if (showTapHint)
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  context.locRead('camera_ar_tap_plane_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
