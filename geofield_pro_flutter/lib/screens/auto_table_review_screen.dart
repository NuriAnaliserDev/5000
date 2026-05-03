import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/ai_translator_service.dart';
import '../services/settings_controller.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_handler.dart';
import '../utils/ai_vertex_error_helper.dart'
    show
        isVertexAiDisabledError,
        isVertexAiQuotaOrBillingError,
        openVertexErrorLink;
import '../utils/app_card.dart';

class AutoTableReviewScreen extends StatefulWidget {
  final String imagePath;
  const AutoTableReviewScreen({super.key, required this.imagePath});

  @override
  State<AutoTableReviewScreen> createState() => _AutoTableReviewScreenState();
}

class _AutoTableReviewScreenState extends State<AutoTableReviewScreen> {
  final AiTranslatorService _aiService = AiTranslatorService();
  bool _isLoading = true;
  Map<String, dynamic>? _parsedData;
  List<Map<String, dynamic>> _tableRows = [];
  String? _analysisError;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _analysisError = null;
        _parsedData = null;
        _tableRows = [];
      });
    }
    final result = await _aiService.analyzeReportImage(widget.imagePath);
    if (!mounted) return;
    if (result.containsKey('error') && result['error'] != null) {
      setState(() {
        _analysisError = result['error'].toString();
        _parsedData = null;
        _tableRows = [];
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _parsedData = result;
      _analysisError = null;
      final type = result['report_type'] ?? 'unknown';
      if (type == 'rc_drill' && result['holes'] != null) {
        _tableRows = List<Map<String, dynamic>>.from(result['holes']);
      } else if (type == 'ore_stockpile' && result['loaders'] != null) {
        _tableRows = List<Map<String, dynamic>>.from(result['loaders']);
      } else if (type == 'ore_block') {
        _tableRows = [Map<String, dynamic>.from(result)];
      }
      _isLoading = false;
    });
  }

  Future<void> _submitReport() async {
    if (_parsedData == null || _analysisError != null) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final settings = context.read<SettingsController>();
      final loc = context.read<LocationService>().currentPosition;
      final uid =
          auth.currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hisobot yuborish uchun avval tizimga kiring.')),
          );
        }
        return;
      }

      // 1. Prepare data
      final updatedTable = List<Map<String, dynamic>>.from(_tableRows);
      final reportType = _parsedData!['report_type'] ?? 'unknown';

      await NetworkExecutor.execute(
        () => FirebaseFirestore.instance.collection('daily_mine_reports').add({
          'reportType': reportType,
          'authorUid': uid,
          'authorName':
              settings.currentUserName ?? auth.currentUser?.email ?? 'Noma\'lum',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'imageUrl': '',
          'lat': loc?.latitude,
          'lng': loc?.longitude,
          'parsedData': {
            'header': {
              'date': _parsedData!['date'],
              'shift': _parsedData!['shift'],
              'driller': _parsedData!['driller'] ??
                  _parsedData!['spotter'] ??
                  _parsedData!['geologist'] ??
                  '—',
              'location': _parsedData!['location'] ?? _parsedData!['pit'] ?? '—',
            },
            'table': updatedTable,
          },
        }),
        actionName: 'Submit Mine Report',
        maxRetries: 2,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Hisobot muvaffaqiyatli Dashboard\'ga yuborildi! ✅')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hisobot Tahlili'),
        actions: [
          if (!_isLoading && _parsedData != null && _analysisError == null)
            TextButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.send, color: Colors.blue),
              label: const Text('YUBORISH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _parsedData == null
              ? _buildErrorState()
              : _buildReviewLayout(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text('AI hujjatni o\'qimoqda...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Bu bir necha soniya vaqt olishi mumkin',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final detail = _analysisError ?? '';
    final s = GeoFieldStrings.of(context);
    final isQuota = isVertexAiQuotaOrBillingError(detail);
    final isApiOff = isVertexAiDisabledError(detail);
    final isVertexUi = (isQuota || isApiOff) && s != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              isQuota && s != null
                  ? s.ai_vertex_quota_billing_title
                  : (isApiOff && s != null
                      ? s.ai_vertex_disabled_title
                      : 'AI tahlil qila olmadi'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (isQuota && s != null) ...[
              const SizedBox(height: 12),
              Text(
                s.ai_vertex_quota_billing_body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.35),
              ),
            ] else if (isApiOff && s != null) ...[
              const SizedBox(height: 12),
              Text(
                s.ai_vertex_disabled_body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.35),
              ),
            ] else if (detail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (isVertexUi) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final ok = await openVertexErrorLink(detail);
                  if (!mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Havolani ochib bo‘lmadi. Brauzer yoki tizim sozlamalarini tekshiring.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(s.ai_vertex_open_console),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startAnalysis,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewLayout() {
    return Column(
      children: [
        // Top Summary Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _summaryItem(
                    'Turi',
                    (_parsedData!['report_type'] ?? '—')
                        .toString()
                        .toUpperCase()),
                _summaryItem('Sana', _parsedData!['date'] ?? '—'),
                _summaryItem('Smena', _parsedData!['shift'] ?? '—'),
              ],
            ),
          ),
        ),

        // Split View or Scrollable Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const Text('Hujjat nusxasi:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPreviewImage(height: 200),
              ),
              const SizedBox(height: 24),
              const Text('AI tomonidan o\'qilgan jadval:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDataTable(),
              const SizedBox(height: 100), // Spacing for bottom
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage({required double height}) {
    final path = widget.imagePath;
    if (path.startsWith('http')) {
      return Image.network(path,
          height: height, width: double.infinity, fit: BoxFit.cover);
    }
    if (kIsWeb) {
      return SizedBox(
          height: height, child: const Center(child: Text('Rasm ko‘rinishi')));
    }
    return Image.file(File(path),
        height: height, width: double.infinity, fit: BoxFit.cover);
  }

  Widget _summaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_tableRows.isEmpty) {
      return const Center(child: Text('Jadval ma\'lumotlari topilmadi'));
    }

    final columns = _tableRows.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        columns: columns
            .map((c) => DataColumn(
                label: Text(c,
                    style: const TextStyle(fontWeight: FontWeight.bold))))
            .toList(),
        rows: _tableRows.map((row) {
          return DataRow(
            cells: columns.map((col) {
              return DataCell(
                TextFormField(
                  initialValue: row[col]?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (val) => row[col] = val,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
