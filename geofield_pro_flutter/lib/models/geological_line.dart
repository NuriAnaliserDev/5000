import 'package:hive/hive.dart';

part 'geological_line.g.dart';

/// Represents a geological linework feature on the map.
/// Supports: fault traces, geological contacts, bedding traces, fold axes, and closed polygons.
@HiveType(typeId: 5)
class GeologicalLine extends HiveObject {
  @HiveField(0)
  String id; // UUID-style unique identifier

  @HiveField(1)
  String name; // e.g. "Fault-001", "Contact-A"

  /// Geological line type. One of:
  /// 'fault' | 'contact' | 'bedding_trace' | 'fold_axis' | 'polygon' | 'other'
  @HiveField(2)
  String lineType;

  @HiveField(3)
  List<double> lats; // latitude of each vertex

  @HiveField(4)
  List<double> lngs; // longitude of each vertex

  @HiveField(5)
  String? colorHex; // e.g. '#FF0000'. Falls back to lineType default color.

  @HiveField(6)
  String? project;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  String? notes;

  /// If true, last point is connected back to first → closed polygon / area.
  @HiveField(9)
  bool isClosed;

  /// Stroke width for rendering.
  @HiveField(10)
  double strokeWidth;

  /// Whether the line should be rendered as dashed (fault-style).
  @HiveField(11)
  bool isDashed;

  /// Whether the line uses Bezier curves for smooth rendering.
  @HiveField(12)
  bool isCurved;

  /// Optional control points for Bezier curves (latitudes).
  @HiveField(13)
  List<double>? controlLats;

  /// Optional control points for Bezier curves (longitudes).
  @HiveField(14)
  List<double>? controlLngs;

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
    this.strokeWidth = 3.0,
    this.isDashed = false,
    this.isCurved = false,
    this.controlLats,
    this.controlLngs,
  });

  /// Default color for each line type (hex string without #)
  static String defaultColorHex(String lineType) {
    switch (lineType) {
      case 'fault':
        return 'FF0000'; // Red
      case 'contact':
        return 'FF8C00'; // Dark Orange
      case 'bedding_trace':
        return '1976D2'; // Blue
      case 'fold_axis':
        return '9C27B0'; // Purple
      case 'polygon':
        return '4CAF50'; // Green
      default:
        return '607D8B'; // Blue-grey
    }
  }

  /// Human-readable line type name (Uzbek)
  static String localizedName(String lineType) {
    switch (lineType) {
      case 'fault':
        return 'Yoriq (Fault)';
      case 'contact':
        return 'Kontakt (Contact)';
      case 'bedding_trace':
        return 'Qatlamlanish izi';
      case 'fold_axis':
        return "Bukilish o'qi";
      case 'polygon':
        return 'Litologik polygon';
      default:
        return 'Boshqa';
    }
  }

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
    };
  }

  factory GeologicalLine.fromMap(Map<String, dynamic> map) {
    return GeologicalLine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lineType: map['lineType'] ?? 'other',
      lats: List<double>.from(map['lats'] ?? []),
      lngs: List<double>.from(map['lngs'] ?? []),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      colorHex: map['colorHex'],
      project: map['project'],
      notes: map['notes'],
      isClosed: map['isClosed'] ?? false,
      strokeWidth: (map['strokeWidth'] ?? 3.0).toDouble(),
      isDashed: map['isDashed'] ?? false,
      isCurved: map['isCurved'] ?? false,
      controlLats: map['controlLats'] != null ? List<double>.from(map['controlLats']) : null,
      controlLngs: map['controlLngs'] != null ? List<double>.from(map['controlLngs']) : null,
    );
  }

}
