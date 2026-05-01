import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_controller.dart';
import '../utils/app_localizations.dart';
import '../utils/app_nav_bar.dart';
import '../utils/app_scroll_physics.dart';

import 'scale/components/scale_calculator_card.dart';
import 'scale/components/scale_layout_card.dart';
import 'scale/components/scale_digital_ruler.dart';
import 'scale/components/scale_color_chart.dart';

class ScaleAssistantScreen extends StatefulWidget {
  const ScaleAssistantScreen({super.key});

  @override
  State<ScaleAssistantScreen> createState() => _ScaleAssistantScreenState();
}

class _ScaleAssistantScreenState extends State<ScaleAssistantScreen> {
  final _realDistController = TextEditingController(text: '100');
  final _paperDistController = TextEditingController();
  
  double _scaleDenominator = 1000; // 1:1000
  final String _unit = 'm'; // 'm' or 'km'

  // Layout Planner State
  final TextEditingController _customWidthCtrl = TextEditingController(text: '21.0');
  final TextEditingController _customHeightCtrl = TextEditingController(text: '29.7');

  String _selectedPaper = 'A4 (21 x 29.7 sm)';
  final List<String> _paperFormats = [
    'A4 (21 x 29.7 sm)', 'A3 (29.7 x 42 sm)', 'A2 (42 x 59.4 sm)', 
    'A1 (59.4 x 84.1 sm)', 'A0 (84.1 x 118.9 sm)', 
    'Millimetrovka A4 (21 x 29.7 sm)', 
    'Millimetrovka A3 (29.7 x 42 sm)',
    'Millimetrovka Rulon (88 sm x 10 m)',
    'custom'
  ];

  @override
  void initState() {
    super.initState();
    _calculatePaperFromReal();
  }

  @override
  void dispose() {
    _realDistController.dispose();
    _paperDistController.dispose();
    _customWidthCtrl.dispose();
    _customHeightCtrl.dispose();
    super.dispose();
  }

  void _calculatePaperFromReal() {
    final real = double.tryParse(_realDistController.text) ?? 0;
    if (real == 0) return;

    double realInMm = _unit == 'm' ? real * 1000 : real * 1000000;
    double paperMm = realInMm / _scaleDenominator;

    setState(() {
      _paperDistController.text = paperMm.toStringAsFixed(1);
    });
  }

  void _calculateRealFromPaper() {
    final paper = double.tryParse(_paperDistController.text) ?? 0;
    if (paper == 0) return;

    double realMm = paper * _scaleDenominator;
    double real = _unit == 'm' ? realMm / 1000 : realMm / 1000000;

    setState(() {
      _realDistController.text = real.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final surf = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        title: Text(context.loc('scale_assistant_title'), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: surf,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.loc('scale_assistant_help_title')),
                  content: Text(
                    context.loc('scale_assistant_help_content'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(context.loc('confirm'))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: AppScrollPhysics.list(),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + AppBottomNavBar.listScrollEndGap(context)),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context.loc('millimetrovka_calc'), Icons.calculate),
                const SizedBox(height: 16),
                ScaleCalculatorCard(
                  realDistController: _realDistController,
                  paperDistController: _paperDistController,
                  unit: _unit,
                  scaleDenominator: _scaleDenominator,
                  onScaleChanged: (s) {
                    setState(() => _scaleDenominator = s);
                    _calculatePaperFromReal();
                  },
                  onRealChanged: _calculatePaperFromReal,
                  onPaperChanged: _calculateRealFromPaper,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(context.loc('layout_planner'), Icons.layers),
                const SizedBox(height: 16),
                ScaleLayoutCard(
                  selectedPaper: _selectedPaper,
                  paperFormats: _paperFormats,
                  customWidthCtrl: _customWidthCtrl,
                  customHeightCtrl: _customHeightCtrl,
                  scaleDenominator: _scaleDenominator,
                  onPaperChanged: (v) => setState(() => _selectedPaper = v),
                  onCustomChanged: () => setState(() {}),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(context.loc('ruler_calibration_title'), Icons.straighten),
                const SizedBox(height: 16),
                ScaleDigitalRuler(settings: settings),
                const SizedBox(height: 32),
                _buildSectionHeader(context.loc('color_chart_title'), Icons.palette),
                const SizedBox(height: 16),
                const ScaleColorChart(),
                const SizedBox(height: 40),
              ],
            ),
          ),
      bottomNavigationBar: const AppBottomNavBar(activeRoute: '/scale-assistant'),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}
