import 'package:hive/hive.dart';
import 'audit_entry.dart';
import 'measurement.dart';

part 'station.g.dart';

@HiveType(typeId: 1)
class Station extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double lat;

  @HiveField(2)
  final double lng;

  @HiveField(3)
  final double altitude;

  @HiveField(4)
  final double strike;

  @HiveField(5)
  final double dip;

  @HiveField(6)
  final double azimuth;

  @HiveField(7)
  final DateTime date;

  @HiveField(8)
  final String? rockType;

  @HiveField(9)
  final String? structure;

  @HiveField(10)
  final String? color;

  @HiveField(11)
  final String? description;

  @HiveField(12)
  final String? photoPath;

  @HiveField(13)
  final String? audioPath;

  @HiveField(14)
  final double? accuracy;

  @HiveField(15)
  final List<String>? photoPaths;

  @HiveField(16)
  final String? project;

  @HiveField(17)
  final String? measurementType;

  @HiveField(18)
  final double? dipDirection;

  @HiveField(19)
  final String? subMeasurementType;

  @HiveField(20)
  final String? sampleId;

  @HiveField(21)
  final String? sampleType;

  @HiveField(22)
  final int? confidence;

  @HiveField(23)
  final String? munsellColor;

  @HiveField(24)
  final String? authorName;

  @HiveField(25)
  final String? authorRole;

  @HiveField(26)
  final List<Measurement>? measurements;

  @HiveField(27)
  final List<AuditEntry>? history;

  @HiveField(28)
  DateTime? updatedAt;

  @HiveField(29, defaultValue: 1)
  int version;

  @HiveField(30)
  String? updatedBy;

  @HiveField(31)
  String? updatedByDeviceId;

  @HiveField(32, defaultValue: false)
  bool isDeleted;

  Station({
    required this.name,
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.strike,
    required this.dip,
    required this.azimuth,
    required this.date,
    this.rockType,
    this.structure,
    this.color,
    this.description,
    this.photoPath,
    this.audioPath,
    this.accuracy,
    this.photoPaths,
    this.project,
    this.measurementType,
    this.dipDirection,
    this.subMeasurementType,
    this.sampleId,
    this.sampleType,
    this.confidence,
    this.munsellColor,
    this.authorName,
    this.authorRole,
    this.measurements,
    this.history,
    this.updatedAt,
    this.version = 1,
    this.updatedBy,
    this.updatedByDeviceId,
    this.isDeleted = false,
  });

  Station copyWith({
    String? name,
    double? lat,
    double? lng,
    double? altitude,
    double? strike,
    double? dip,
    double? azimuth,
    DateTime? date,
    String? rockType,
    String? structure,
    String? color,
    String? description,
    String? photoPath,
    String? audioPath,
    double? accuracy,
    List<String>? photoPaths,
    String? project,
    String? measurementType,
    double? dipDirection,
    String? subMeasurementType,
    String? sampleId,
    String? sampleType,
    int? confidence,
    String? munsellColor,
    String? authorName,
    String? authorRole,
    List<Measurement>? measurements,
    List<AuditEntry>? history,
    DateTime? updatedAt,
    int? version,
    String? updatedBy,
    String? updatedByDeviceId,
    bool? isDeleted,
  }) {
    return Station(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      altitude: altitude ?? this.altitude,
      strike: strike ?? this.strike,
      dip: dip ?? this.dip,
      azimuth: azimuth ?? this.azimuth,
      date: date ?? this.date,
      rockType: rockType ?? this.rockType,
      structure: structure ?? this.structure,
      color: color ?? this.color,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      audioPath: audioPath ?? this.audioPath,
      accuracy: accuracy ?? this.accuracy,
      photoPaths: photoPaths ?? this.photoPaths,
      project: project ?? this.project,
      measurementType: measurementType ?? this.measurementType,
      dipDirection: dipDirection ?? this.dipDirection,
      subMeasurementType: subMeasurementType ?? this.subMeasurementType,
      sampleId: sampleId ?? this.sampleId,
      sampleType: sampleType ?? this.sampleType,
      confidence: confidence ?? this.confidence,
      munsellColor: munsellColor ?? this.munsellColor,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      measurements: measurements ?? this.measurements,
      history: history ?? this.history,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'altitude': altitude,
      'strike': strike,
      'dip': dip,
      'azimuth': azimuth,
      'date': date.toIso8601String(),
      'rockType': rockType,
      'structure': structure,
      'color': color,
      'description': description,
      'photoPath': photoPath,
      'audioPath': audioPath,
      'accuracy': accuracy,
      'photoPaths': photoPaths,
      'project': project,
      'measurementType': measurementType,
      'dipDirection': dipDirection,
      'subMeasurementType': subMeasurementType,
      'sampleId': sampleId,
      'sampleType': sampleType,
      'confidence': confidence,
      'munsellColor': munsellColor,
      'authorName': authorName,
      'authorRole': authorRole,
      'measurements': measurements?.map((e) => e.toMap()).toList(),
      'history': history?.map((e) => e.toMap()).toList(),
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
      'updatedBy': updatedBy,
      'updatedByDeviceId': updatedByDeviceId,
      'isDeleted': isDeleted,
    };
  }

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      name: map['name'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      strike: (map['strike'] as num?)?.toDouble() ?? 0.0,
      dip: (map['dip'] as num?)?.toDouble() ?? 0.0,
      azimuth: (map['azimuth'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      rockType: map['rockType'],
      structure: map['structure'],
      color: map['color'],
      description: map['description'],
      photoPath: map['photoPath'],
      audioPath: map['audioPath'],
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      photoPaths: (map['photoPaths'] as List?)?.cast<String>(),
      project: map['project'],
      measurementType: map['measurementType'],
      dipDirection: (map['dipDirection'] as num?)?.toDouble(),
      subMeasurementType: map['subMeasurementType'],
      sampleId: map['sampleId'],
      sampleType: map['sampleType'],
      confidence: map['confidence'] as int?,
      munsellColor: map['munsellColor'],
      authorName: map['authorName'],
      authorRole: map['authorRole'],
      measurements: (map['measurements'] as List?)
          ?.map((e) => Measurement.fromMap(e as Map<String, dynamic>))
          .toList(),
      history: (map['history'] as List?)
          ?.map((e) => AuditEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      version: map['version'] ?? 1,
      updatedBy: map['updatedBy'],
      updatedByDeviceId: map['updatedByDeviceId'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
