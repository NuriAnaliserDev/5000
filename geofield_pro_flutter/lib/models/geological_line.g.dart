// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geological_line.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeologicalLineAdapter extends TypeAdapter<GeologicalLine> {
  @override
  final int typeId = 5;

  @override
  GeologicalLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeologicalLine(
      id: fields[0] as String,
      name: fields[1] as String,
      lineType: fields[2] as String,
      lats: (fields[3] as List).cast<double>(),
      lngs: (fields[4] as List).cast<double>(),
      date: fields[7] as DateTime,
      colorHex: fields[5] as String?,
      project: fields[6] as String?,
      notes: fields[8] as String?,
      isClosed: fields[9] as bool,
      strokeWidth: fields[10] as double,
      isDashed: fields[11] as bool,
      isCurved: fields[12] as bool,
      controlLats: (fields[13] as List?)?.cast<double>(),
      controlLngs: (fields[14] as List?)?.cast<double>(),
      updatedAt: fields[15] as DateTime?,
      version: fields[16] == null ? 1 : fields[16] as int,
      updatedBy: fields[17] as String?,
      updatedByDeviceId: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GeologicalLine obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lineType)
      ..writeByte(3)
      ..write(obj.lats)
      ..writeByte(4)
      ..write(obj.lngs)
      ..writeByte(5)
      ..write(obj.colorHex)
      ..writeByte(6)
      ..write(obj.project)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.isClosed)
      ..writeByte(10)
      ..write(obj.strokeWidth)
      ..writeByte(11)
      ..write(obj.isDashed)
      ..writeByte(12)
      ..write(obj.isCurved)
      ..writeByte(13)
      ..write(obj.controlLats)
      ..writeByte(14)
      ..write(obj.controlLngs)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.version)
      ..writeByte(17)
      ..write(obj.updatedBy)
      ..writeByte(18)
      ..write(obj.updatedByDeviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeologicalLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
