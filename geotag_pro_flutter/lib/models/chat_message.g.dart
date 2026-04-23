// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 3;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      groupId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      text: fields[4] as String,
      timestamp: fields[5] as DateTime,
      status: fields[6] as String,
      messageType: fields[7] as String,
      mediaPath: fields[8] as String?,
      lat: fields[9] as double?,
      lng: fields[10] as double?,
      editedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.text)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.messageType)
      ..writeByte(8)
      ..write(obj.mediaPath)
      ..writeByte(9)
      ..write(obj.lat)
      ..writeByte(10)
      ..write(obj.lng)
      ..writeByte(11)
      ..write(obj.editedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
