import 'package:hive_flutter/hive_flutter.dart';

part 'geological_line.g.dart';

@HiveType(typeId: 5)
class GeologicalLine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String lineType;

  @HiveField(3)
  final List<double> lats;

  @HiveField(4)
  final List<double> lngs;

  @HiveField(5)
  final String? colorHex;

  @HiveField(6)
  final String? project;

  @HiveField(7)
  final DateTime date;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final bool isClosed;

  @HiveField(10)
  final double strokeWidth;

  @HiveField(11)
  final bool isDashed;

  @HiveField(12)
  final bool isCurved;

  @HiveField(13)
  final List<double>? controlLats;

  @HiveField(14)
  final List<double>? controlLngs;

  @HiveField(15)
  DateTime? updatedAt;

  @HiveField(16, defaultValue: 1)
  int version;

  @HiveField(17)
  String? updatedBy;

  @HiveField(18)
  String? updatedByDeviceId;

  @HiveField(19, defaultValue: false)
  bool isDeleted;

  GeologicalLine({
    required this.id,
    required this.name,
    required this.lineType,
    required this.lats,
    required this.lngs,
    required this.date,
    this.colorHex,
    this.project,
    this.notes,
    this.isClosed = false,
    this.strokeWidth = 2.0,
    this.isDashed = false,
    this.isCurved = false,
    this.controlLats,
    this.controlLngs,
    this.updatedAt,
    this.version = 1,
    this.updatedBy,
    this.updatedByDeviceId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lineType': lineType,
      'lats': lats,
      'lngs': lngs,
      'colorHex': colorHex,
      'project': project,
      'date': date.toIso8601String(),
      'notes': notes,
      'isClosed': isClosed,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'isCurved': isCurved,
      'controlLats': controlLats,
      'controlLngs': controlLngs,
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
      'updatedBy': updatedBy,
      'updatedByDeviceId': updatedByDeviceId,
      'isDeleted': isDeleted,
    };
  }

  factory GeologicalLine.fromMap(Map<String, dynamic> map) {
    return GeologicalLine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lineType: map['lineType'] ?? '',
      lats: (map['lats'] as List?)?.cast<double>() ?? [],
      lngs: (map['lngs'] as List?)?.cast<double>() ?? [],
      date: DateTime.parse(map['date']),
      colorHex: map['colorHex'],
      project: map['project'],
      notes: map['notes'],
      isClosed: map['isClosed'] ?? false,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      isDashed: map['isDashed'] ?? false,
      isCurved: map['isCurved'] ?? false,
      controlLats: (map['controlLats'] as List?)?.cast<double>(),
      controlLngs: (map['controlLngs'] as List?)?.cast<double>(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      version: map['version'] ?? 1,
      updatedBy: map['updatedBy'],
      updatedByDeviceId: map['updatedByDeviceId'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  GeologicalLine copyWith({
    String? id,
    String? name,
    String? lineType,
    List<double>? lats,
    List<double>? lngs,
    String? colorHex,
    String? project,
    DateTime? date,
    String? notes,
    bool? isClosed,
    double? strokeWidth,
    bool? isDashed,
    bool? isCurved,
    List<double>? controlLats,
    List<double>? controlLngs,
    DateTime? updatedAt,
    int? version,
    String? updatedBy,
    String? updatedByDeviceId,
    bool? isDeleted,
  }) {
    return GeologicalLine(
      id: id ?? this.id,
      name: name ?? this.name,
      lineType: lineType ?? this.lineType,
      lats: lats ?? this.lats,
      lngs: lngs ?? this.lngs,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
      project: project ?? this.project,
      notes: notes ?? this.notes,
      isClosed: isClosed ?? this.isClosed,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      isCurved: isCurved ?? this.isCurved,
      controlLats: controlLats ?? this.controlLats,
      controlLngs: controlLngs ?? this.controlLngs,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
  static String defaultColorHex(String type) {
    switch (type.toLowerCase()) {
      case 'fault': return '0xFFFF0000'; // Red
      case 'thrust': return '0xFF800080'; // Purple
      case 'normal_fault': return '0xFFFF0000'; 
      case 'anticline': return '0xFF0000FF'; // Blue
      case 'syncline': return '0xFF0000FF'; // Blue
      case 'bedding': return '0xFF000000'; // Black
      case 'contact': return '0xFF000000'; // Black
      case 'joint': return '0xFF808080'; // Gray
      case 'vein': return '0xFF00FFFF'; // Cyan
      case 'dike': return '0xFFFFD700'; // Gold
      default: return '0xFF000000';
    }
  }

  static String localizedName(String type) {
    // Shunchaki katta harf bilan qaytaramiz yoki lug'atdan olamiz
    switch (type.toLowerCase()) {
      case 'fault': return 'Yoriq';
      case 'thrust': return 'Surilma';
      case 'anticline': return 'Antiklinal';
      case 'syncline': return 'Sinklinal';
      case 'bedding': return 'Qatlamlanish';
      default: return type.toUpperCase();
    }
  }
}
