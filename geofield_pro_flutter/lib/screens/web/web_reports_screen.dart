import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/mine_report_repository.dart';
import '../../services/excel_generator_service.dart';
import '../../models/mine_report.dart';
import 'components/web_verification_terminal.dart';

class WebReportsScreen extends StatefulWidget {
  const WebReportsScreen({super.key});

  @override
  State<WebReportsScreen> createState() => _WebReportsScreenState();
}

class _WebReportsScreenState extends State<WebReportsScreen>
    with SingleTickerProviderStateMixin {
  MineReport? _selectedReport;
  bool _isExporting = false;
  late TabController _tabController;

  // Tab filtr turlari
  final List<_TabConfig> _tabs = const [
    _TabConfig(label: 'Ore Block', icon: Icons.fire_truck, type: 'ore_block', color: Color(0xFF1565C0)),
    _TabConfig(label: 'RC Burg\'ulash', icon: Icons.precision_manufacturing, type: 'rc_drill', color: Color(0xFF6A1B9A)),
    _TabConfig(label: 'Ore Stockpile', icon: Icons.stacked_bar_chart, type: 'ore_stockpile', color: Color(0xFF2E7D32)),
    _TabConfig(label: 'Spotter Log', icon: Icons.assignment, type: 'spotter', color: Color(0xFFE65100)),
    _TabConfig(label: 'Drilling Tally', icon: Icons.straighten, type: 'drilling', color: Color(0xFFBF360C)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      // Tab o'zgarganda tanlangan hisobotni bekor qilish
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedReport = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentType => _tabs[_tabController.index].type;
  Color get _currentColor => _tabs[_tabController.index].color;

  Future<void> _exportVerifiedData() async {
    setState(() => _isExporting = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('daily_mine_reports')
          .where('status', isEqualTo: 'verified')
          .where('reportType', isEqualTo: _currentType)
          .orderBy('createdAt', descending: false)
          .get();

      final List<MineReport> reports = snap.docs.map((d) {
        return MineReport.fromFirestore(d);
      }).toList();

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Eksport qilish uchun Tasdiqlangan ma'lumot yo'q!")),
          );
        }
        return;
      }

      final excelService = ExcelGeneratorService();
      await excelService.generateAndDownload(reports);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ma'lumotlar muvaffaqiyatli yuklab olindi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _generateMasterReport() async {
    setState(() => _isExporting = true);
    try {
      // Barcha turlardagi verified hisobotlarni yig'ish
      final snap = await FirebaseFirestore.instance
          .collection('daily_mine_reports')
          .where('status', isEqualTo: 'verified')
          .orderBy('createdAt', descending: false)
          .get();

      final List<MineReport> reports = snap.docs.map((d) => MineReport.fromFirestore(d)).toList();

      if (reports.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu yerda tasdiqlangan ma'lumotlar yo'q!")));
        }
        return;
      }

      await ExcelGeneratorService().generateAndDownload(reports);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Master Report muvaffaqiyatli hosil qilindi!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Master Report xatosi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qabulxona (Inbox)', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 16),
                const SizedBox(width: 6),
                Text(tab.label),
              ],
            ),
          )).toList(),
          labelColor: _currentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _currentColor,
          isScrollable: false,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: _isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.summarize, size: 18),
              label: Text(_isExporting ? "JARAYONDA..." : "MASTER REPORT (HISOBOT)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _isExporting ? null : _generateMasterReport,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: _isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download, size: 18),
              label: Text(_isExporting ? "YUKLANMOQDA..." : "EKSPORT (TANLANGAN)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _isExporting ? null : _exportVerifiedData,
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildTabContent(t, tab)).toList(),
      ),
    );
  }

  Widget _buildTabContent(ThemeData t, _TabConfig tab) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chap: Pending hisobotlar ro'yxati
        Container(
          width: 320,
          margin: const EdgeInsets.only(left: 16, bottom: 16, right: 8, top: 8),
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tab.color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: tab.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tasdiq Kutayotganlar — ${tab.label}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tab.color),
                      ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: Consumer<MineReportRepository>(
                  builder: (context, repo, _) {
                    return StreamBuilder<List<MineReport>>(
                      stream: repo.streamPendingReportsByType(tab.type),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  "Yangi hisobot yo'q",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        final reports = snapshot.data!;
                        return ListView.separated(
                          itemCount: reports.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            final isSelected = _selectedReport?.id == report.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: tab.color.withValues(alpha: 0.08),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: tab.color.withValues(alpha: 0.15),
                                child: Icon(tab.icon, color: tab.color, size: 18),
                              ),
                              title: Text(
                                report.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                DateFormat('dd-MM-yyyy HH:mm').format(report.createdAt),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.arrow_forward_ios, size: 14, color: tab.color)
                                  : const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                              onTap: () => setState(() => _selectedReport = report),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // O'ng: Tasdiqlash terminali
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16, bottom: 16, top: 8),
            decoration: BoxDecoration(
              color: t.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: _selectedReport == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Chapdan hisobotni tanlang",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tab.label,
                          style: TextStyle(color: tab.color, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : WebVerificationTerminal(
                    key: ValueKey(_selectedReport!.id),
                    report: _selectedReport!,
                    onDismiss: () => setState(() => _selectedReport = null),
                  ),
          ),
        ),
      ],
    );
  }
}

// Tab konfiguratsiyasi
class _TabConfig {
  final String label;
  final IconData icon;
  final String type;
  final Color color;
  const _TabConfig({required this.label, required this.icon, required this.type, required this.color});
}
