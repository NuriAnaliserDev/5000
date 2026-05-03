import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../services/mine_report_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/ai_translator_service.dart';
import '../../../models/mine_report.dart';

class WebVerificationTerminal extends StatefulWidget {
  final MineReport report;
  final VoidCallback? onDismiss; // Tasdiqlash/rad etishdan keyin chaqiriladi

  const WebVerificationTerminal({
    super.key,
    required this.report,
    this.onDismiss,
  });

  @override
  State<WebVerificationTerminal> createState() => _WebVerificationTerminalState();
}

class _WebVerificationTerminalState extends State<WebVerificationTerminal> {
  late Map<String, dynamic> _formData;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _isRejecting = false;
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = Map<String, dynamic>.from(widget.report.parsedData);
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers.clear();
    _formData.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });
  }

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: _formData[key]?.toString() ?? '');
    }
    return _controllers[key]!;
  }

  @override
  void didUpdateWidget(WebVerificationTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _formData = Map<String, dynamic>.from(widget.report.parsedData);
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ─── Form maydonlari — tur bo'yicha ───────────────────────────────────────
  Widget _buildFormFields() {
    switch (widget.report.reportType) {
      case 'ore_block':
        return ListView(
          children: [
            _buildTextField('Pit (Masalan: P1, P2)', 'pit'),
            _buildTextField('Gorizont (RL Toe)', 'horizon'),
            _buildTextField('Blok Raqami (Markup)', 'markup'),
            _buildTextField('To\'liq Blok (#)', 'block_full'),
            _buildTextField('Destination (MARG/SKLAD)', 'destination'),
            _buildTextField('Grade / Material (g/t)', 'grade'),
            _buildTextField('Yuklar Soni (Total Loads)', 'total_loads', isNumber: true),
            _buildTextField('Spoter', 'spotter'),
            _buildTextField('Ekskavator #', 'excavator', isNumber: true),
            _buildTextField('Sana', 'date'),
          ],
        );
      case 'rc_drill':
        return ListView(
          children: [
            _buildTextField('Rig ID', 'rig_id'),
            _buildTextField('Rig Model', 'rig_model'),
            _buildTextField('Contractor', 'contractor'),
            _buildTextField('Loyiha', 'project'),
            _buildTextField('Sana', 'date'),
            _buildTextField('Quduq ID', 'hole_id'),
            _buildTextField('Chuqurlik (m)', 'depth', isNumber: true),
            _buildTextField('Namuna Qayerdan (From)', 'sample_from'),
            _buildTextField('Namuna Qayergacha (To)', 'sample_to'),
            _buildTextField('Namuna Soni (#)', 'sample_count', isNumber: true),
            _buildTextField('Jami Chuqurlik', 'total_depth'),
            _buildTextField('Kechikish Sababi (Downtime)', 'downtime_cause'),
          ],
        );
      case 'ore_stockpile':
        return ListView(
          children: [
            _buildTextField('Sana', 'date'),
            _buildTextField('Smena', 'shift'),
            _buildTextField('Geolog', 'geologist'),
            _buildTextField('Jami Yuklar (Grand Total)', 'grand_total', isNumber: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Loader ma\'lumotlari AI tomonidan o\'qiladi',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      case 'spotter':
      case 'drilling':
        return _buildAiReportForm();
      default:
        // Noma'lum tur — barcha mavjud maydonlarni ko'rsatish
        return ListView(
          children: _formData.keys
              .where((k) => k != 'report_type')
              .map((key) => _buildTextField(key, key))
              .toList(),
        );
    }
  }

  Widget _buildAiReportForm() {
    final header = _formData['header'] as Map<String, dynamic>? ?? {};
    final table = _formData['table'] as List? ?? [];

    return ListView(
      children: [
        const Text('ASOSIY MA\'LUMOTLAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        _buildTextField('Sana', 'header.date', initialValue: header['date']),
        _buildTextField('Smena', 'header.shift', initialValue: header['shift']),
        _buildTextField('Uchastka', 'header.location', initialValue: header['location']),
        _buildTextField('Xodim', 'header.driller', initialValue: header['driller']),
        const SizedBox(height: 16),
        const Text('HISOBOT JADVALI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        if (table.isEmpty)
          const Text('Jadval bo\'sh', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 30,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 40,
              border: TableBorder.all(color: Colors.grey.shade200),
              columns: (table.first as Map).keys.map((k) => DataColumn(label: Text(k.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))).toList(),
              rows: table.map((row) {
                final cells = (row as Map).keys.map((k) {
                  return DataCell(
                    TextFormField(
                      initialValue: row[k]?.toString() ?? '',
                      style: const TextStyle(fontSize: 10),
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (val) => row[k] = val,
                    ),
                  );
                }).toList();
                return DataRow(cells: cells);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: initialValue != null ? (TextEditingController(text: initialValue)) : _getController(key),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13),
        onChanged: (val) {
          if (key.startsWith('header.')) {
            final hKey = key.split('.')[1];
            _formData['header'][hKey] = val;
          } else {
            _formData[key] = val;
          }
        },
      ),
    );
  }

  // ─── AI tahlil ────────────────────────────────────────────────────────────
  Future<void> _runAiAnalysis() async {
    if (widget.report.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hujjat rasmi yo'q!")),
      );
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      final aiService = AiTranslatorService();
      final aiResult = await aiService.analyzeReportImage(widget.report.imageUrl);

      if (aiResult.containsKey('error')) {
        throw Exception(aiResult['error']);
      }

      setState(() {
        aiResult.forEach((key, value) {
          if (value != null) {
            _formData[key] = value;
            _getController(key).text = value.toString();
          }
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("AI rasmni muvaffaqiyatli tahlil qildi!"),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI Xatosi: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  // ─── Tasdiqlash ───────────────────────────────────────────────────────────
  Future<void> _verify() async {
    setState(() => _isSaving = true);
    try {
      final repo = context.read<MineReportRepository>();
      final auth = context.read<AuthService>();
      final userName = auth.currentUser?.email ?? 'Admin';
      await repo.verifyReport(widget.report.id, _formData, userName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Muvaffaqiyatli tasdiqlandi!"), backgroundColor: Colors.green),
        );
        widget.onDismiss?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Rad etish ───────────────────────────────────────────────────────────
  Future<void> _reject() async {
    final repo = context.read<MineReportRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hisobotni rad etish?'),
        content: const Text(
          'Bu hisobot o\'chirib tashlanadi va qayta tiklanmaydi.\nDavom etilsinmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => ctx.pop(true),
            child: const Text('Rad etish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRejecting = true);
    try {
      await repo.deleteReport(widget.report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Hisobot rad etildi."), backgroundColor: Colors.orange),
      );
      widget.onDismiss?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  // ─── Tur rangi ────────────────────────────────────────────────────────────
  Color get _typeColor {
    switch (widget.report.reportType) {
      case 'ore_block': return const Color(0xFF1565C0);
      case 'rc_drill': return const Color(0xFF6A1B9A);
      case 'ore_stockpile': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  String get _typeLabel {
    switch (widget.report.reportType) {
      case 'ore_block': return '⛏️ Ore Block';
      case 'rc_drill': return '🔩 RC Burg\'ulash';
      case 'ore_stockpile': return '📊 Ore Stockpile';
      default: return widget.report.reportType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Row(
      children: [
        // 1. Asl Rasm paneli
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.black87,
            child: widget.report.imageUrl.isNotEmpty
                ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.report.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) =>
                          const Center(child: Text("Rasm yuklanmadi", style: TextStyle(color: Colors.grey))),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                    ),
                  )
                : const Center(child: Text("Rasm yo'q", style: TextStyle(color: Colors.white54))),
          ),
        ),

        Container(width: 1, color: t.dividerColor),

        // 2. Xarita + forma
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // GPS Xarita
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: (widget.report.lat != null && widget.report.lng != null)
                            ? LatLng(widget.report.lat!, widget.report.lng!)
                            : const LatLng(41.2995, 69.2401),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aurum.geofieldpro',
                        ),
                        if (widget.report.lat != null && widget.report.lng != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(widget.report.lat!, widget.report.lng!),
                                width: 40,
                                height: 40,
                                child: Icon(Icons.location_on, color: _typeColor, size: 40),
                              )
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "📍 ${widget.report.authorName}",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tahrirlash paneli
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  color: t.colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tur badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _typeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          "$_typeLabel — ${widget.report.authorName}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: _typeColor, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // AI tugmasi
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          icon: _isAiLoading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isAiLoading ? "AI O'QIMOQDA..." : "🤖 AI AUTO-FILL",
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isAiLoading ? null : _runAiAnalysis,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Formalar
                      Expanded(child: _buildFormFields()),

                      const SizedBox(height: 10),

                      // Tugmalar qatori: RAD ETISH | TASDIQLASH
                      Row(
                        children: [
                          // Rad etish
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                icon: _isRejecting
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                    : const Icon(Icons.close, size: 16),
                                label: const Text("RAD ETISH", style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: (_isSaving || _isRejecting) ? null : _reject,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tasdiqlash
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                icon: _isSaving
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.verified, size: 16),
                                label: Text(
                                  _isSaving ? "SAQLANMOQDA..." : "TASDIQLASH",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: (_isSaving || _isRejecting) ? null : _verify,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
