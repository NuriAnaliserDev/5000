import 'package:hive/hive.dart';

part 'chat_group.g.dart';

@HiveType(typeId: 4)
class ChatGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? lastMessage;

  @HiveField(4)
  DateTime? lastMessageTime;

  @HiveField(5)
  int unreadCount;

  @HiveField(6)
  String? project; // Specific project this group belongs to, or null if open

  @HiveField(7)
  List<String>? allowedRoles; // 'Sampler', 'Geologist', etc.

  ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.project,
    this.allowedRoles,
  });
}
