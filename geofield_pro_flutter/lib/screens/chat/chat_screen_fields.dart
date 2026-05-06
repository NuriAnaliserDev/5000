part of '../chat_screen.dart';

mixin ChatScreenFields on State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
}
