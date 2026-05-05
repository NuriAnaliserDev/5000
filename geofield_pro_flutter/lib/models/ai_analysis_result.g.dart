// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_analysis_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIAnalysisResultAdapter extends TypeAdapter<AIAnalysisResult> {
  @override
  final int typeId = 13;

  @override
  AIAnalysisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIAnalysisResult(
      rockType: fields[0] as String,
      mineralogy: (fields[1] as List).cast<String>(),
      texture: fields[2] as String,
      structure: fields[3] as String,
      color: fields[4] as String,
      munsellApprox: fields[5] as String,
      confidence: fields[6] as double,
      notes: fields[7] as String,
      analyzedAt: fields[8] as DateTime,
      status: fields[9] == null ? 'valid' : fields[9] as String,
      warningMessage: fields[10] == null ? '' : fields[10] as String,
      trustScore: fields[11] == null ? 0.0 : fields[11] as double,
      isReliable: fields[12] == null ? false : fields[12] as bool,
      trustReasons:
          fields[13] == null ? [] : (fields[13] as List).cast<String>(),
      aiModelVersion: fields[14] == null ? 1 : fields[14] as int,
      rockCandidates:
          fields[15] == null ? [] : (fields[15] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIAnalysisResult obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.rockType)
      ..writeByte(1)
      ..write(obj.mineralogy)
      ..writeByte(2)
      ..write(obj.texture)
      ..writeByte(3)
      ..write(obj.structure)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.munsellApprox)
      ..writeByte(6)
      ..write(obj.confidence)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.analyzedAt)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.warningMessage)
      ..writeByte(11)
      ..write(obj.trustScore)
      ..writeByte(12)
      ..write(obj.isReliable)
      ..writeByte(13)
      ..write(obj.trustReasons)
      ..writeByte(14)
      ..write(obj.aiModelVersion)
      ..writeByte(15)
      ..write(obj.rockCandidates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIAnalysisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
