import 'package:flutter/material.dart';

bool geologicalArSupportedPlatform() => false;

class GeologicalArSessionController {
  Future<String?> captureToTempFile() async => null;
}

class GeologicalArView extends StatefulWidget {
  const GeologicalArView({
    super.key,
    required this.onControllerReady,
    required this.onDisposed,
  });

  final ValueChanged<GeologicalArSessionController> onControllerReady;
  final VoidCallback onDisposed;

  @override
  State<GeologicalArView> createState() => _GeologicalArViewStateStub();
}

class _GeologicalArViewStateStub extends State<GeologicalArView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady(GeologicalArSessionController());
    });
  }

  @override
  void dispose() {
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}
