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

  AuditEntry({
    required this.timestamp,
    required this.author,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
  });

  @override
  String toString() {
    return '[$timestamp] $author o\'zgartirdi: $fieldName ($oldValue -> $newValue)';
  }
}
