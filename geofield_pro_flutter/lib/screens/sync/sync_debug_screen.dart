import 'package:flutter/material.dart';
import '../../services/sync/sync_queue_service.dart';
import '../../services/sync/sync_processor.dart';
import '../../services/sync/conflict_queue_service.dart';
import '../../core/di/dependency_injection.dart';
import '../../models/sync_item.dart';

class SyncDebugScreen extends StatelessWidget {
  const SyncDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = sl<SyncQueueService>();
    final processor = sl<SyncProcessor>();
    final conflicts = sl<ConflictQueueService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Sync Diagnostics',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
            onPressed: () => processor.run(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(processor),
            const SizedBox(height: 24),
            _buildSectionTitle('STATISTIKA'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildStatTile(
                        'NAVBT', '${queue.pendingItems.length}', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatTile('KONFLIKT',
                        '${conflicts.conflictCount}', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatTile(
                        'XATO', '${queue.failedItems.length}', Colors.red)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('OXIRGI XATOLIK'),
            const SizedBox(height: 12),
            _buildErrorLog(processor.lastError),
            const SizedBox(height: 32),
            _buildSectionTitle('QUEUE ITEMS (TOP 10)'),
            const SizedBox(height: 12),
            _buildQueueList(queue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SyncProcessor processor) {
    Color statusColor;
    String statusText;
    IconData icon;

    switch (processor.status) {
      case SyncEngineStatus.idle:
        statusColor = const Color(0xFF10B981); // Emerald Green
        statusText = 'Kutilmoqda';
        icon = Icons.check_circle_outline_rounded;
        break;
      case SyncEngineStatus.syncing:
        statusColor = Colors.blue;
        statusText = 'Sinxronizatsiya...';
        icon = Icons.sync_rounded;
        break;
      case SyncEngineStatus.error:
        statusColor = Colors.red;
        statusText = 'Xatolik';
        icon = Icons.error_outline_rounded;
        break;
      case SyncEngineStatus.noInternet:
        statusColor = Colors.orange;
        statusText = 'Internet yo\'q';
        icon = Icons.wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ENGINE STATUS',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text(statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildErrorLog(String? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error != null
            ? Colors.red.withOpacity(0.05)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: error != null
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        error ?? 'Hech qanday xatolik qayd etilmadi',
        style: TextStyle(
            color: error != null ? Colors.red[200] : Colors.white38,
            fontSize: 13,
            fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildQueueList(SyncQueueService queue) {
    final items = queue.pendingItems.take(10).toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child:
                Text('Navbat bo\'sh', style: TextStyle(color: Colors.white24))),
      );
    }

    return Column(
      children: items.map((item) => _buildQueueItem(item)).toList(),
    );
  }

  Widget _buildQueueItem(SyncItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            item.operation == SyncOperation.create
                ? Icons.add_box_rounded
                : item.operation == SyncOperation.update
                    ? Icons.edit_note_rounded
                    : Icons.delete_sweep_rounded,
            color: Colors.white24,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.entityType,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('Seq: ${item.sequence} | Retries: ${item.retryCount}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(item.status.name.toUpperCase(),
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
