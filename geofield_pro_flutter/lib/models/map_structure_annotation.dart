import 'package:hive/hive.dart';

part 'map_structure_annotation.g.dart';

/// Xaritada qo‘lda qo‘yilgan strike/dip (Field Move uslubida struktur nuqtasi).
@HiveType(typeId: 8)
class MapStructureAnnotation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double lat;

  @HiveField(2)
  double lng;

  /// Strike, shimoldan soat yo‘nalishida, 0–360
  @HiveField(3)
  double strike;

  /// Dip, 0–90
  @HiveField(4)
  double dip;

  /// Turi: 'bedding' | 'cleavage' | 'lineation' | 'joint' | 'contact' | 'fault' | 'other'
  @HiveField(5)
  String structureType;

  @HiveField(6)
  String? note;

  @HiveField(7)
  DateTime createdAt;

  MapStructureAnnotation({
    required this.id,
    required this.lat,
    required this.lng,
    required this.strike,
    required this.dip,
    required this.structureType,
    required this.createdAt,
    this.note,
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
    };
  }

  factory MapStructureAnnotation.fromMap(Map<String, dynamic> m) {
    return MapStructureAnnotation(
      id: m['id'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      strike: (m['strike'] as num?)?.toDouble() ?? 0,
      dip: (m['dip'] as num?)?.toDouble() ?? 0,
      structureType: m['structureType'] as String? ?? 'bedding',
      note: m['note'] as String?,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
