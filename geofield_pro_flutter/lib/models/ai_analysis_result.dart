import 'package:hive/hive.dart';

part 'ai_analysis_result.g.dart';

@HiveType(typeId: 13)
class AIAnalysisResult extends HiveObject {
  @HiveField(0)
  final String rockType;

  @HiveField(1)
  final List<String> mineralogy;

  @HiveField(2)
  final String texture;

  @HiveField(3)
  final String structure;

  @HiveField(4)
  final String color;

  @HiveField(5)
  final String munsellApprox;

  @HiveField(6)
  final double confidence;

  @HiveField(7)
  final String notes;

  @HiveField(8)
  final DateTime analyzedAt;

  @HiveField(9, defaultValue: 'valid')
  final String status;

  @HiveField(10, defaultValue: '')
  final String warningMessage;

  AIAnalysisResult({
    required this.rockType,
    required this.mineralogy,
    required this.texture,
    required this.structure,
    required this.color,
    required this.munsellApprox,
    required this.confidence,
    required this.notes,
    required this.analyzedAt,
    this.status = 'valid',
    this.warningMessage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'rockType': rockType,
      'mineralogy': mineralogy,
      'texture': texture,
      'structure': structure,
      'color': color,
      'munsellApprox': munsellApprox,
      'confidence': confidence,
      'notes': notes,
      'analyzedAt': analyzedAt.toIso8601String(),
      'status': status,
      'warningMessage': warningMessage,
    };
  }

  factory AIAnalysisResult.fromMap(Map<String, dynamic> map) {
    return AIAnalysisResult(
      rockType: map['rockType'] ?? 'Unknown',
      mineralogy: List<String>.from(map['mineralogy'] ?? []),
      texture: map['texture'] ?? '',
      structure: map['structure'] ?? '',
      color: map['color'] ?? '',
      munsellApprox: map['munsellApprox'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      analyzedAt: map['analyzedAt'] != null 
          ? DateTime.parse(map['analyzedAt']) 
          : DateTime.now(),
      status: map['status'] ?? 'valid',
      warningMessage: map['warningMessage'] ?? '',
    );
  }
}
