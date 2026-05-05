import 'package:hive_flutter/hive_flutter.dart';

part 'map_structure_annotation.g.dart';

@HiveType(typeId: 8)
class MapStructureAnnotation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double lat;

  @HiveField(2)
  final double lng;

  @HiveField(3)
  final double strike;

  @HiveField(4)
  final double dip;

  @HiveField(5)
  final String structureType;

  @HiveField(6)
  final String? note;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  @HiveField(9, defaultValue: 1)
  int version;

  @HiveField(10)
  String? updatedBy;

  @HiveField(11)
  String? updatedByDeviceId;

  @HiveField(12, defaultValue: false)
  bool isDeleted;

  MapStructureAnnotation({
    required this.id,
    required this.lat,
    required this.lng,
    required this.strike,
    required this.dip,
    required this.structureType,
    required this.createdAt,
    this.note,
    this.updatedAt,
    this.version = 1,
    this.updatedBy,
    this.updatedByDeviceId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'strike': strike,
      'dip': dip,
      'structureType': structureType,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
      'updatedBy': updatedBy,
      'updatedByDeviceId': updatedByDeviceId,
      'isDeleted': isDeleted,
    };
  }

  factory MapStructureAnnotation.fromMap(Map<String, dynamic> m) {
    return MapStructureAnnotation(
      id: m['id'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
      strike: (m['strike'] as num?)?.toDouble() ?? 0.0,
      dip: (m['dip'] as num?)?.toDouble() ?? 0.0,
      structureType: m['structureType'] as String? ?? '',
      note: m['note'] as String?,
      createdAt: DateTime.parse(m['createdAt']),
      updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : null,
      version: m['version'] ?? 1,
      updatedBy: m['updatedBy'] as String?,
      updatedByDeviceId: m['updatedByDeviceId'] as String?,
      isDeleted: m['isDeleted'] as bool? ?? false,
    );
  }

  MapStructureAnnotation copyWith({
    String? id,
    double? lat,
    double? lng,
    double? strike,
    double? dip,
    String? structureType,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? updatedBy,
    String? updatedByDeviceId,
    bool? isDeleted,
  }) {
    return MapStructureAnnotation(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      strike: strike ?? this.strike,
      dip: dip ?? this.dip,
      structureType: structureType ?? this.structureType,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
