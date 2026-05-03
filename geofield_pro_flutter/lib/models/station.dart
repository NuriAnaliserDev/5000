import 'package:hive/hive.dart';
import 'audit_entry.dart';
import 'measurement.dart';

part 'station.g.dart';

@HiveType(typeId: 1)
class Station extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double lat;

  @HiveField(2)
  double lng;

  @HiveField(3)
  double altitude;

  @HiveField(4)
  double strike;

  @HiveField(5)
  double dip;

  @HiveField(6)
  double azimuth;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  String? rockType;

  @HiveField(9)
  String? structure;

  @HiveField(10)
  String? color;

  @HiveField(11)
  String? description;

  @Deprecated(
      'Use photoPaths instead. This is kept for backward compatibility.')
  @HiveField(12)
  String? photoPath;

  @HiveField(13)
  String? audioPath;

  // Real GPS accuracy (meters) at capture time (may be null for old records)
  @HiveField(14)
  double? accuracy;

  // Multiple photos per station (new). Keep photoPath for backward compat/UI thumb.
  @HiveField(15)
  List<String>? photoPaths;

  // Project/expedition grouping
  @HiveField(16)
  String? project;

  @HiveField(17)
  String? measurementType;

  @HiveField(18)
  double? dipDirection;

  @HiveField(19)
  String? subMeasurementType;

  @HiveField(20)
  String? sampleId;

  @HiveField(21)
  String? sampleType;

  @HiveField(22)
  int? confidence;

  @HiveField(23)
  String? munsellColor;

  @HiveField(24)
  String? authorName;

  @HiveField(25)
  String? authorRole;

  @HiveField(26)
  List<Measurement>? measurements;

  @HiveField(27)
  List<AuditEntry>? history;

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
    this.sampleId,
    this.sampleType,
    this.confidence,
    this.munsellColor,
    this.authorName,
    this.authorRole,
    this.measurements,
    this.history,
    this.subMeasurementType,
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
    String? subMeasurementType,
    double? dipDirection,
    String? sampleId,
    String? sampleType,
    int? confidence,
    String? munsellColor,
    String? authorName,
    String? authorRole,
    List<Measurement>? measurements,
    List<AuditEntry>? history,
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
      subMeasurementType: subMeasurementType ?? this.subMeasurementType,
      dipDirection: dipDirection ?? this.dipDirection,
      sampleId: sampleId ?? this.sampleId,
      sampleType: sampleType ?? this.sampleType,
      confidence: confidence ?? this.confidence,
      munsellColor: munsellColor ?? this.munsellColor,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      measurements: measurements ?? this.measurements,
      history: history ?? this.history,
    );
  }
}
