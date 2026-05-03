// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_structure_annotation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapStructureAnnotationAdapter
    extends TypeAdapter<MapStructureAnnotation> {
  @override
  final int typeId = 8;

  @override
  MapStructureAnnotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapStructureAnnotation(
      id: fields[0] as String,
      lat: fields[1] as double,
      lng: fields[2] as double,
      strike: fields[3] as double,
      dip: fields[4] as double,
      structureType: fields[5] as String,
      createdAt: fields[7] as DateTime,
      note: fields[6] as String?,
      updatedAt: fields[8] as DateTime?,
      version: fields[9] == null ? 1 : fields[9] as int,
      updatedBy: fields[10] as String?,
      updatedByDeviceId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MapStructureAnnotation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lng)
      ..writeByte(3)
      ..write(obj.strike)
      ..writeByte(4)
      ..write(obj.dip)
      ..writeByte(5)
      ..write(obj.structureType)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.version)
      ..writeByte(10)
      ..write(obj.updatedBy)
      ..writeByte(11)
      ..write(obj.updatedByDeviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapStructureAnnotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
