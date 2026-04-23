// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditEntryAdapter extends TypeAdapter<AuditEntry> {
  @override
  final int typeId = 7;

  @override
  AuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditEntry(
      timestamp: fields[0] as DateTime,
      author: fields[1] as String,
      fieldName: fields[2] as String,
      oldValue: fields[3] as String,
      newValue: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuditEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.author)
      ..writeByte(2)
      ..write(obj.fieldName)
      ..writeByte(3)
      ..write(obj.oldValue)
      ..writeByte(4)
      ..write(obj.newValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
