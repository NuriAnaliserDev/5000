import 'package:hive/hive.dart';

part 'sync_item.g.dart';

@HiveType(typeId: 10)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  done,
  @HiveField(3)
  failed,
  @HiveField(4)
  permanentlyFailed
}

@HiveType(typeId: 11)
enum SyncOperation {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete
}

@HiveType(typeId: 9)
class SyncItem extends HiveObject {
  @HiveField(0)
  final String id; // Internal Hive key / UUID

  @HiveField(1)
  final String entityType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final int version;

  @HiveField(5)
  SyncStatus status;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final SyncOperation operation;

  @HiveField(9)
  final String requestId; // For idempotency on server

  @HiveField(10)
  final int sequence; // Monotonic order

  static const int maxRetries = 5;

  SyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.version,
    required this.operation,
    required this.requestId,
    required this.sequence,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
  });
}
