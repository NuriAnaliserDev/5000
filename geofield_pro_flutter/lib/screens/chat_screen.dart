import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_repository.dart';
import '../services/location_service.dart';
import '../services/cloud_sync_service.dart';
import '../models/chat_message.dart';
import '../app/main_tab_navigation.dart';

part 'chat/chat_screen_fields.dart';
part 'chat/chat_screen_logic.dart';
part 'chat/chat_screen_ui.dart';
part 'chat/chat_screen_state.dart';

class ChatScreen extends StatefulWidget {
  final String groupId;

  const ChatScreen({super.key, required this.groupId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
