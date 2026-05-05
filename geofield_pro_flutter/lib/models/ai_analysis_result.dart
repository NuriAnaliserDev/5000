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

  @HiveField(11, defaultValue: 0.0)
  final double trustScore;

  @HiveField(12, defaultValue: false)
  final bool isReliable;

  @HiveField(13, defaultValue: [])
  final List<String> trustReasons;

  @HiveField(14, defaultValue: 1)
  final int aiModelVersion;

  @HiveField(15, defaultValue: [])
  final List<String> rockCandidates;

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
    this.trustScore = 0.0,
    this.isReliable = false,
    this.trustReasons = const [],
    this.aiModelVersion = 1,
    this.rockCandidates = const [],
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
      'trustScore': trustScore,
      'isReliable': isReliable,
      'trustReasons': trustReasons,
      'aiModelVersion': aiModelVersion,
      'rockCandidates': rockCandidates,
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
      trustScore: (map['trustScore'] ?? 0.0).toDouble(),
      isReliable: map['isReliable'] ?? false,
      trustReasons: List<String>.from(map['trustReasons'] ?? []),
      aiModelVersion: map['aiModelVersion'] ?? 1,
      rockCandidates: List<String>.from(map['rockCandidates'] ?? []),
    );
  }
}
