import 'package:hive/hive.dart';

part 'measurement.g.dart';

@HiveType(typeId: 6)
class Measurement extends HiveObject {
  /// Measurement type, e.g., 'bedding', 'cleavage', 'lineation', 'joint', 'contact', 'fault', 'other'
  @HiveField(0)
  String type;

  /// Strike angle (0-360 degrees)
  @HiveField(1)
  double strike;

  /// Dip angle (0-90 degrees)
  @HiveField(2)
  double dip;

  /// Dip direction (0-360 degrees, usually strike + 90 or strike - 90)
  @HiveField(3)
  double dipDirection;

  /// Optional notes for this specific measurement
  @HiveField(4)
  String? notes;

  /// Timestamp when this measurement was taken
  @HiveField(5)
  DateTime capturedAt;

  Measurement({
    required this.type,
    required this.strike,
    required this.dip,
    required this.dipDirection,
    required this.capturedAt,
    this.notes,
  });

  /// Human-readable type
  String get localizedType {
    switch (type) {
      case 'bedding':
        return 'Qatlamlanish (S0)';
      case 'cleavage':
        return 'Klivaj (S1/S2)';
      case 'lineation':
        return 'Lineatsiya (L)';
      case 'joint':
        return 'Yoriq (Joint)';
      case 'contact':
        return 'Kontakt';
      case 'fault':
        return 'Sinish (Fault)';
      default:
        return 'Boshqa';
    }
  }

  Measurement copyWith({
    String? type,
    double? strike,
    double? dip,
    double? dipDirection,
    String? notes,
    DateTime? capturedAt,
  }) {
    return Measurement(
      type: type ?? this.type,
      strike: strike ?? this.strike,
      dip: dip ?? this.dip,
      dipDirection: dipDirection ?? this.dipDirection,
      notes: notes ?? this.notes,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'strike': strike,
      'dip': dip,
      'dipDirection': dipDirection,
      'notes': notes,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      type: map['type'] ?? '',
      strike: (map['strike'] as num?)?.toDouble() ?? 0.0,
      dip: (map['dip'] as num?)?.toDouble() ?? 0.0,
      dipDirection: (map['dipDirection'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      capturedAt: DateTime.parse(map['capturedAt']),
    );
  }
}
