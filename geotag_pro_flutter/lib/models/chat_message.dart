import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 3)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String groupId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  String text;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  String status; // 'pending', 'sent', 'error'

  @HiveField(7)
  String messageType; // 'text', 'image', 'audio'

  @HiveField(8)
  String? mediaPath;

  @HiveField(9)
  double? lat;

  @HiveField(10)
  double? lng;

  /// So‘nggi tahrir vaqti (bulut bilan sinxron).
  @HiveField(11)
  DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.status,
    this.messageType = 'text',
    this.mediaPath,
    this.lat,
    this.lng,
    this.editedAt,
  });
}
