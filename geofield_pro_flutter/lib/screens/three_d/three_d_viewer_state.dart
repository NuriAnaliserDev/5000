part of '../three_d_viewer_screen.dart';

class _ThreeDViewerScreenState extends State<ThreeDViewerScreen>
    with ThreeDViewerStateFields {
  @override
  void initState() {
    super.initState();
    final repo = context.read<StationRepository>();
    final stations = repo.stations;

    if (stations.isNotEmpty) {
      _center =
          widget.centerPoint ?? LatLng(stations.first.lat, stations.first.lng);
      _avgAlt = stations.map((e) => e.altitude).reduce((a, b) => a + b) /
          stations.length;
    } else {
      _center = const LatLng(0, 0);
      _avgAlt = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationRepository>().stations;
    final s = GeoFieldStrings.of(context);

    if (stations.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: Text(
            s?.three_d_structure ?? '3D',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s?.viewer_3d_no_data ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 15, height: 1.4),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          s?.three_d_structure ?? '3D',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _rotationX = 0.5;
              _rotationY = 0.5;
              _zoom = 1.0;
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _rotationY += details.delta.dx * 0.01;
            _rotationX -= details.delta.dy * 0.01;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: Structural3DViewerPainter(
                  stations: stations,
                  center: _center,
                  centerAlt: _avgAlt,
                  rotX: _rotationX,
                  rotY: _rotationY,
                  zoom: _zoom,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    s?.viewer_3d_nothing_visible ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 100 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      s?.viewer_3d_legend ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final pad = MediaQuery.of(context).padding;
    return Positioned(
      bottom: 12 + pad.bottom,
      right: 12,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A2028),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () =>
                    setState(() => _zoom = (_zoom * 1.2).clamp(0.2, 8.0)),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () =>
                    setState(() => _zoom = (_zoom / 1.2).clamp(0.2, 8.0)),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
