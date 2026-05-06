part of '../cross_section_screen.dart';

class _CrossSectionScreenState extends State<CrossSectionScreen>
    with CrossSectionStateFields, CrossSectionUiMixin {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StationRepository>();
    final data = _service.generateProfile(
      start: widget.start,
      end: widget.end,
      stations: repo.stations,
      bufferMeters: _buffer,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Geologik Kesim (Profile)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSettings(colorScheme),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AppCard(
                baseColor: Colors.white.withValues(alpha: 0.05),
                borderRadius: 20,
                child: ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrossSectionProfilePainter(
                      data: data,
                      exaggeration: _exaggeration,
                      totalLength: const Distance()
                          .as(LengthUnit.Meter, widget.start, widget.end),
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildStatsSummary(data),
        ],
      ),
    );
  }
}
