import 'package:hive/hive.dart';

part 'sync_conflict.g.dart';

@HiveType(typeId: 12)
class SyncConflict extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityId;

  @HiveField(2)
  final String entityType; // station, line, annotation

  @HiveField(3)
  final Map<String, dynamic> localData;

  @HiveField(4)
  final Map<String, dynamic> remoteData;

  @HiveField(5)
  final DateTime detectedAt;

  @HiveField(6)
  final String? resolvedBy; // 'local', 'remote', 'manual'

  SyncConflict({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.localData,
    required this.remoteData,
    required this.detectedAt,
    this.resolvedBy,
  });
}
