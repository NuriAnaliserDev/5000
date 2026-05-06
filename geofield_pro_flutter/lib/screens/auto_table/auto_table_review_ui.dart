part of '../auto_table_review_screen.dart';

mixin AutoTableReviewUiMixin on AutoTableReviewLogicMixin {
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
              const SizedBox(height: 100),
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
