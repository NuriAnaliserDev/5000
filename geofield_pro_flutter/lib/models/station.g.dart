// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StationAdapter extends TypeAdapter<Station> {
  @override
  final int typeId = 1;

  @override
  Station read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Station(
      name: fields[0] as String,
      lat: fields[1] as double,
      lng: fields[2] as double,
      altitude: fields[3] as double,
      strike: fields[4] as double,
      dip: fields[5] as double,
      azimuth: fields[6] as double,
      date: fields[7] as DateTime,
      rockType: fields[8] as String?,
      structure: fields[9] as String?,
      color: fields[10] as String?,
      description: fields[11] as String?,
      photoPath: fields[12] as String?,
      audioPath: fields[13] as String?,
      accuracy: fields[14] as double?,
      photoPaths: (fields[15] as List?)?.cast<String>(),
      project: fields[16] as String?,
      measurementType: fields[17] as String?,
      dipDirection: fields[18] as double?,
      subMeasurementType: fields[19] as String?,
      sampleId: fields[20] as String?,
      sampleType: fields[21] as String?,
      confidence: fields[22] as int?,
      munsellColor: fields[23] as String?,
      authorName: fields[24] as String?,
      authorRole: fields[25] as String?,
      measurements: (fields[26] as List?)?.cast<Measurement>(),
      history: (fields[27] as List?)?.cast<AuditEntry>(),
      updatedAt: fields[28] as DateTime?,
      version: fields[29] == null ? 1 : fields[29] as int,
      updatedBy: fields[30] as String?,
      updatedByDeviceId: fields[31] as String?,
      isDeleted: fields[32] == null ? false : fields[32] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Station obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lng)
      ..writeByte(3)
      ..write(obj.altitude)
      ..writeByte(4)
      ..write(obj.strike)
      ..writeByte(5)
      ..write(obj.dip)
      ..writeByte(6)
      ..write(obj.azimuth)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.rockType)
      ..writeByte(9)
      ..write(obj.structure)
      ..writeByte(10)
      ..write(obj.color)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.photoPath)
      ..writeByte(13)
      ..write(obj.audioPath)
      ..writeByte(14)
      ..write(obj.accuracy)
      ..writeByte(15)
      ..write(obj.photoPaths)
      ..writeByte(16)
      ..write(obj.project)
      ..writeByte(17)
      ..write(obj.measurementType)
      ..writeByte(18)
      ..write(obj.dipDirection)
      ..writeByte(19)
      ..write(obj.subMeasurementType)
      ..writeByte(20)
      ..write(obj.sampleId)
      ..writeByte(21)
      ..write(obj.sampleType)
      ..writeByte(22)
      ..write(obj.confidence)
      ..writeByte(23)
      ..write(obj.munsellColor)
      ..writeByte(24)
      ..write(obj.authorName)
      ..writeByte(25)
      ..write(obj.authorRole)
      ..writeByte(26)
      ..write(obj.measurements)
      ..writeByte(27)
      ..write(obj.history)
      ..writeByte(28)
      ..write(obj.updatedAt)
      ..writeByte(29)
      ..write(obj.version)
      ..writeByte(30)
      ..write(obj.updatedBy)
      ..writeByte(31)
      ..write(obj.updatedByDeviceId)
      ..writeByte(32)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
