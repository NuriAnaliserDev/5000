part of 'web_verification_terminal.dart';

mixin _WebVerificationTerminalPart on State<WebVerificationTerminal> {
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
      _controllers[key] =
          TextEditingController(text: _formData[key]?.toString() ?? '');
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
  Widget vtBuildFormFields() {
    switch (widget.report.reportType) {
      case 'ore_block':
        return ListView(
          children: [
            vtBuildTextField('Pit (Masalan: P1, P2)', 'pit'),
            vtBuildTextField('Gorizont (RL Toe)', 'horizon'),
            vtBuildTextField('Blok Raqami (Markup)', 'markup'),
            vtBuildTextField('To\'liq Blok (#)', 'block_full'),
            vtBuildTextField('Destination (MARG/SKLAD)', 'destination'),
            vtBuildTextField('Grade / Material (g/t)', 'grade'),
            vtBuildTextField('Yuklar Soni (Total Loads)', 'total_loads',
                isNumber: true),
            vtBuildTextField('Spoter', 'spotter'),
            vtBuildTextField('Ekskavator #', 'excavator', isNumber: true),
            vtBuildTextField('Sana', 'date'),
          ],
        );
      case 'rc_drill':
        return ListView(
          children: [
            vtBuildTextField('Rig ID', 'rig_id'),
            vtBuildTextField('Rig Model', 'rig_model'),
            vtBuildTextField('Contractor', 'contractor'),
            vtBuildTextField('Loyiha', 'project'),
            vtBuildTextField('Sana', 'date'),
            vtBuildTextField('Quduq ID', 'hole_id'),
            vtBuildTextField('Chuqurlik (m)', 'depth', isNumber: true),
            vtBuildTextField('Namuna Qayerdan (From)', 'sample_from'),
            vtBuildTextField('Namuna Qayergacha (To)', 'sample_to'),
            vtBuildTextField('Namuna Soni (#)', 'sample_count', isNumber: true),
            vtBuildTextField('Jami Chuqurlik', 'total_depth'),
            vtBuildTextField('Kechikish Sababi (Downtime)', 'downtime_cause'),
          ],
        );
      case 'ore_stockpile':
        return ListView(
          children: [
            vtBuildTextField('Sana', 'date'),
            vtBuildTextField('Smena', 'shift'),
            vtBuildTextField('Geolog', 'geologist'),
            vtBuildTextField('Jami Yuklar (Grand Total)', 'grand_total',
                isNumber: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Loader ma\'lumotlari AI tomonidan o\'qiladi',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      case 'spotter':
      case 'drilling':
        return vtBuildAiReportForm();
      default:
        return ListView(
          children: _formData.keys
              .where((k) => k != 'report_type')
              .map((key) => vtBuildTextField(key, key))
              .toList(),
        );
    }
  }

  Widget vtBuildAiReportForm() {
    final header = _formData['header'] as Map<String, dynamic>? ?? {};
    final table = _formData['table'] as List? ?? [];

    return ListView(
      children: [
        const Text('ASOSIY MA\'LUMOTLAR',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1,
                color: Colors.blueGrey)),
        const SizedBox(height: 8),
        vtBuildTextField('Sana', 'header.date', initialValue: header['date']),
        vtBuildTextField('Smena', 'header.shift', initialValue: header['shift']),
        vtBuildTextField('Uchastka', 'header.location',
            initialValue: header['location']),
        vtBuildTextField('Xodim', 'header.driller',
            initialValue: header['driller']),
        const SizedBox(height: 16),
        const Text('HISOBOT JADVALI',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1,
                color: Colors.blueGrey)),
        const SizedBox(height: 8),
        if (table.isEmpty)
          const Text('Jadval bo\'sh',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 30,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 40,
              border: TableBorder.all(color: Colors.grey.shade200),
              columns: (table.first as Map)
                  .keys
                  .map((k) => DataColumn(
                      label: Text(k.toString(),
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold))))
                  .toList(),
              rows: table.map((row) {
                final cells = (row as Map).keys.map((k) {
                  return DataCell(
                    TextFormField(
                      initialValue: row[k]?.toString() ?? '',
                      style: const TextStyle(fontSize: 10),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
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

  Widget vtBuildTextField(String label, String key,
      {bool isNumber = false, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: initialValue != null
            ? (TextEditingController(text: initialValue))
            : _getController(key),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
  Future<void> vtRunAiAnalysis() async {
    if (widget.report.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hujjat rasmi yo'q!")),
      );
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      final aiService = AiTranslatorService();
      final aiResult =
          await aiService.analyzeReportImage(widget.report.imageUrl);

      if (aiResult.containsKey('error')) {
        throw AppError(aiResult['error'], category: ErrorCategory.unknown);
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
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  // ─── Tasdiqlash ───────────────────────────────────────────────────────────
  Future<void> vtVerify() async {
    setState(() => _isSaving = true);
    try {
      final repo = context.read<MineReportRepository>();
      final auth = context.read<AuthService>();
      final userName = auth.currentUser?.email ?? 'Admin';
      await repo.verifyReport(widget.report.id, _formData, userName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Muvaffaqiyatli tasdiqlandi!"),
              backgroundColor: Colors.green),
        );
        widget.onDismiss?.call();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Rad etish ───────────────────────────────────────────────────────────
  Future<void> vtReject() async {
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        const SnackBar(
            content: Text("🗑️ Hisobot rad etildi."),
            backgroundColor: Colors.orange),
      );
      widget.onDismiss?.call();
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  Color get vtTypeColor {
    switch (widget.report.reportType) {
      case 'ore_block':
        return const Color(0xFF1565C0);
      case 'rc_drill':
        return const Color(0xFF6A1B9A);
      case 'ore_stockpile':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  String get vtTypeLabel {
    switch (widget.report.reportType) {
      case 'ore_block':
        return '⛏️ Ore Block';
      case 'rc_drill':
        return '🔩 RC Burg\'ulash';
      case 'ore_stockpile':
        return '📊 Ore Stockpile';
      default:
        return widget.report.reportType;
    }
  }
}
