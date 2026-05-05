import 'package:hive/hive.dart';

part 'audit_entry.g.dart';

@HiveType(typeId: 7)
class AuditEntry extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String author;

  @HiveField(2)
  final String fieldName;

  @HiveField(3)
  final String oldValue;

  @HiveField(4)
  final String newValue;

  @HiveField(5)
  final String? action; // 'create', 'update', 'delete', 'sync'

  @HiveField(6)
  final String? status; // 'success', 'error', 'conflict'

  @HiveField(7)
  final String? errorMessage;

  AuditEntry({
    required this.timestamp,
    required this.author,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    this.action,
    this.status,
    this.errorMessage,
  });

  @override
  String toString() {
    if (action == 'sync') {
      return '[$timestamp] SYNC $status: $errorMessage';
    }
    return '[$timestamp] $author o\'zgartirdi: $fieldName ($oldValue -> $newValue)';
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'author': author,
      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
      'action': action,
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      timestamp: DateTime.parse(map['timestamp']),
      author: map['author'] ?? '',
      fieldName: map['fieldName'] ?? '',
      oldValue: map['oldValue'] ?? '',
      newValue: map['newValue'] ?? '',
      action: map['action'],
      status: map['status'],
      errorMessage: map['errorMessage'],
    );
  }
}
