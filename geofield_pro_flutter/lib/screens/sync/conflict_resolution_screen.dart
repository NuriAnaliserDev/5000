import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sync_conflict.dart';
import '../../services/sync/conflict_queue_service.dart';
import '../../services/station_repository.dart';
import '../../services/geological_line_repository.dart';
import '../../services/map_structure_repository.dart';
import '../../core/di/dependency_injection.dart';
import '../../models/station.dart';
import '../../models/geological_line.dart';
import '../../models/map_structure_annotation.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  @override
  Widget build(BuildContext context) {
    final conflictService = sl<ConflictQueueService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      appBar: AppBar(
        title: const Text('Ma\'lumotlar To\'qnashuvi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: conflictService.listenable,
        builder: (context, box, _) {
          final conflicts = conflictService.conflicts;

          if (conflicts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conflicts.length,
            itemBuilder: (context, index) => _buildConflictCard(conflicts[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: Colors.emerald.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Barcha ma\'lumotlar xavfsiz',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Hech qanday to\'qnashuv aniqlanmadi',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictCard(SyncConflict conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.entityType.toUpperCase(),
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Text(
                        'ID: ${conflict.entityId}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _buildResolutionButton(conflict),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildComparisonView(conflict),
        ],
      ),
    );
  }

  Widget _buildComparisonView(SyncConflict conflict) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildDataColumn('LOKAL', conflict.localData, Colors.blue)),
          const SizedBox(width: 16),
          const Icon(Icons.compare_arrows_rounded, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(child: _buildDataColumn('BULUT', conflict.remoteData, Colors.emerald)),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String label, Map<String, dynamic> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Versiya', '${data['version']}'),
              _buildField('Nomi', '${data['name'] ?? data['id']}'),
              Text(
                'Batafsil ko\'rish...',
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResolutionButton(SyncConflict conflict) {
    return ElevatedButton(
      onPressed: () => _showResolutionDialog(conflict),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Hal qilish'),
    );
  }

  void _showResolutionDialog(SyncConflict conflict) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Qaror qabul qiling',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ushbu ma\'lumotning qaysi varianti saqlansin?',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildDialogOption(
              icon: Icons.smartphone_rounded,
              title: 'Lokal variantni saqlash',
              subtitle: 'Bulutdagi ma\'lumot ustidan yoziladi',
              color: Colors.blue,
              onTap: () => _resolve(conflict, 'local'),
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              icon: Icons.cloud_done_rounded,
              title: 'Bulutdagi variantni saqlash',
              subtitle: 'Lokal ma\'lumot yangilanadi',
              color: Colors.emerald,
              onTap: () => _resolve(conflict, 'remote'),
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              icon: Icons.merge_type_rounded,
              title: 'Qo\'lda birlashtirish (Yaqinda)',
              subtitle: 'Har bir maydonni alohida tanlash',
              color: Colors.white24,
              onTap: null, // Tezkunda
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(SyncConflict conflict, String decision) async {
    Navigator.pop(context);
    
    final resolutionRequestId = 'conflict_${conflict.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Resolution mantiqi
    if (decision == 'local') {
      await _handleLocalWin(conflict, resolutionRequestId);
    } else if (decision == 'remote') {
      await _handleRemoteWin(conflict);
    }

    await sl<ConflictQueueService>().resolveConflict(conflict.id);
    
    // 3. SyncEngine'ni darrov trigger qilamiz
    sl<SyncProcessor>().run();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('To\'qnashuv hal qilindi: ${decision.toUpperCase()}'),
        backgroundColor: Colors.emerald,
      ),
    );
  }

  Future<void> _handleLocalWin(SyncConflict conflict, String requestId) async {
    // Local versiyani remotedan bitta baland qilamiz (majburiy overwrite uchun)
    final remoteVersion = conflict.remoteData['version'] as int? ?? 0;
    final newLocalVersion = remoteVersion + 1;

    switch (conflict.entityType) {
      case 'station':
        final s = Station.fromMap(conflict.localData).copyWith(version: newLocalVersion);
        await sl<StationRepository>().updateStation(
          conflict.entityId, 
          s, 
          source: UpdateSource.local,
          customRequestId: requestId,
        );
        break;
      case 'geological_line':
        final l = GeologicalLine.fromMap(conflict.localData).copyWith(version: newLocalVersion);
        await sl<GeologicalLineRepository>().updateLine(
          l, 
          source: UpdateSource.local,
          customRequestId: requestId,
        );
        break;
      case 'map_annotation':
        final a = MapStructureAnnotation.fromMap(conflict.localData).copyWith(version: newLocalVersion);
        await sl<MapStructureRepository>().updateAnnotation(
          a, 
          source: UpdateSource.local,
          customRequestId: requestId,
        );
        break;
    }
  }

  Future<void> _handleRemoteWin(SyncConflict conflict) async {
    switch (conflict.entityType) {
      case 'station':
        final s = Station.fromMap(conflict.remoteData);
        await sl<StationRepository>().updateStation(conflict.entityId, s, source: UpdateSource.cloud);
        break;
      case 'geological_line':
        final l = GeologicalLine.fromMap(conflict.remoteData);
        await sl<GeologicalLineRepository>().updateLine(conflict.entityId, l, source: UpdateSource.cloud);
        break;
      case 'map_annotation':
        final a = MapStructureAnnotation.fromMap(conflict.remoteData);
        await sl<MapStructureRepository>().updateAnnotation(conflict.entityId, a, source: UpdateSource.cloud);
        break;
    }
  }
}
