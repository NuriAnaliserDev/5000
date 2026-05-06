part of '../cross_section_screen.dart';

mixin CrossSectionUiMixin on CrossSectionStateFields {
  Widget _buildSettings(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.line_weight, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Buffer (Masofa): ${_buffer.toInt()} m',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Slider(
                value: _buffer,
                min: 50,
                max: 2000,
                divisions: 39,
                onChanged: (v) => setState(() => _buffer = v),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.height, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Exaggeration (Bo\'rttirish): ${_exaggeration.toStringAsFixed(1)}x',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Slider(
                value: _exaggeration,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                onChanged: (v) => setState(() => _exaggeration = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<CrossSectionData> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Nuqtalar', data.length.toString(), Icons.analytics),
          _statItem(
              'Masofa',
              '${const Distance().as(LengthUnit.Meter, widget.start, widget.end).toInt()} m',
              Icons.straighten),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white30, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
