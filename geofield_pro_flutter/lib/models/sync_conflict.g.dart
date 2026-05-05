// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_conflict.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncConflictAdapter extends TypeAdapter<SyncConflict> {
  @override
  final int typeId = 12;

  @override
  SyncConflict read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncConflict(
      id: fields[0] as String,
      entityId: fields[1] as String,
      entityType: fields[2] as String,
      localData: (fields[3] as Map).cast<String, dynamic>(),
      remoteData: (fields[4] as Map).cast<String, dynamic>(),
      detectedAt: fields[5] as DateTime,
      resolvedBy: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncConflict obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityId)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.localData)
      ..writeByte(4)
      ..write(obj.remoteData)
      ..writeByte(5)
      ..write(obj.detectedAt)
      ..writeByte(6)
      ..write(obj.resolvedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncConflictAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
