// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatGroupAdapter extends TypeAdapter<ChatGroup> {
  @override
  final int typeId = 4;

  @override
  ChatGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      lastMessage: fields[3] as String?,
      lastMessageTime: fields[4] as DateTime?,
      unreadCount: fields[5] as int,
      project: fields[6] as String?,
      allowedRoles: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatGroup obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.lastMessage)
      ..writeByte(4)
      ..write(obj.lastMessageTime)
      ..writeByte(5)
      ..write(obj.unreadCount)
      ..writeByte(6)
      ..write(obj.project)
      ..writeByte(7)
      ..write(obj.allowedRoles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
