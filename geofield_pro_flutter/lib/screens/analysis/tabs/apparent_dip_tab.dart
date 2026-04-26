import 'package:flutter/material.dart';
import '../../../l10n/app_strings.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/app_scroll_physics.dart';
import '../../../utils/geology_utils.dart';

class ApparentDipTab extends StatefulWidget {
  const ApparentDipTab({super.key});

  @override
  State<ApparentDipTab> createState() => _ApparentDipTabState();
}

class _ApparentDipTabState extends State<ApparentDipTab> {
  final _dipCtrl = TextEditingController(text: '45');
  final _dipDirCtrl = TextEditingController(text: '180');
  final _sectionCtrl = TextEditingController(text: '270');
  double? _result;

  @override
  void dispose() {
    _dipCtrl.dispose();
    _dipDirCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final trueDip = double.tryParse(_dipCtrl.text);
    final dipDir = double.tryParse(_dipDirCtrl.text);
    final section = double.tryParse(_sectionCtrl.text);
    if (trueDip == null || dipDir == null || section == null) {
      setState(() => _result = null);
      return;
    }
    setState(() {
      _result = GeologyUtils.apparentDip(
        trueDip: trueDip.clamp(0, 90),
        dipDirection: (dipDir % 360 + 360) % 360,
        sectionAzimuth: (section % 360 + 360) % 360,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.grey.shade100;

    Widget inputRow(String label, TextEditingController ctrl) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: onSurf.withValues(alpha: 0.8))),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffix: const Text('°'),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF222222) : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: AppScrollPhysics.list(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.loc('apparent_dip_calc_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0xFF1976D2), fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          context.loc('apparent_dip_formula_hint'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.loc('input_data'), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF1976D2), fontWeight: FontWeight.w900)),
              const Divider(height: 20, color: Color(0xFF1976D2)),
              inputRow(context.loc('apparent_true_dip'), _dipCtrl),
              inputRow(context.loc('apparent_dip_direction'), _dipDirCtrl),
              inputRow(context.loc('apparent_section_azimuth'), _sectionCtrl),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calculate),
                  label: Text(context.loc('calculate'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Text(context.loc('apparent_dip_title'), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white70, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('${_result!.toStringAsFixed(2)}°', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _result! / 90.0,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  GeoFieldStrings.of(context)!.apparent_result_hint(
                    _dipCtrl.text,
                    _result!.toStringAsFixed(1),
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc('note'), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF1976D2), fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  context.loc('apparent_note_body'),
                  style: TextStyle(fontSize: 11, color: onSurf.withValues(alpha: 0.6), height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
