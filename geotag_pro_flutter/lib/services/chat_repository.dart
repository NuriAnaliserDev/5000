import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/chat_group.dart';
import 'hive_db.dart';
import 'settings_controller.dart';

class ChatRepository extends ChangeNotifier {
  final Box<ChatMessage> _messagesBox = Hive.box<ChatMessage>(HiveDb.chatMessagesBox);
  final Box<ChatGroup> _groupsBox = Hive.box<ChatGroup>(HiveDb.chatGroupsBox);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _chatSubscriptions = [];

  final SettingsController settingsController;

  ChatRepository({required this.settingsController}) {
    _initDefaultGroups();
    _startRealtimeChatSync();
  }

  void _startRealtimeChatSync() {
    for (final group in _groupsBox.values) {
      _subscribeToGroup(group.id);
    }
  }

  void _subscribeToGroup(String groupId) {
    final sub = _firestore
        .collection('chat_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) async {
      bool changed = false;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] as String?;
        if (id == null || id.isEmpty) continue;

        final existing = _messagesBox.get(id);
        final senderName = (data['senderName'] as String?) ?? 'Noma\'lum';
        final senderId = (data['senderId'] as String?) ?? 'anon';
        final text = (data['text'] as String?) ?? '';
        final messageType = (data['messageType'] as String?) ?? 'text';
        final mediaUrl = data['mediaUrl'] as String?;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final ts = DateTime.tryParse((data['timestamp'] as String?) ?? '') ?? DateTime.now();

        if (existing == null) {
          await _messagesBox.put(
            id,
            ChatMessage(
              id: id,
              groupId: groupId,
              senderId: senderId,
              senderName: senderName,
              text: text,
              timestamp: ts,
              status: 'sent',
              messageType: messageType,
              mediaPath: mediaUrl,
              lat: lat,
              lng: lng,
            ),
          );
          changed = true;
          continue;
        }

        if (existing.status != 'sent') {
          existing.status = 'sent';
          await existing.save();
          changed = true;
        }
      }

      if (changed) {
        await _refreshGroupMetadata(groupId);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Realtime chat sync failed for $groupId: $e');
    });
    _chatSubscriptions.add(sub);
  }

  void _initDefaultGroups() {
    if (_groupsBox.isEmpty) {
      final generalGroup = ChatGroup(
        id: 'general',
        name: 'Umumiy Markaz',
        description: 'Barcha ishtirokchilar uchun umumiy guruh',
        project: 'Default',
      );
      _groupsBox.put('general', generalGroup);
      
      final sosGroup = ChatGroup(
        id: 'sos_channel',
        name: 'Favqulodda / SOS',
        description: 'Tezkor holatlar uchun markaz',
        project: 'Default',
      );
      _groupsBox.put('sos_channel', sosGroup);
    }
  }

  Future<void> _refreshGroupMetadata(String groupId) async {
    final group = _groupsBox.get(groupId);
    if (group == null) return;
    final messages = getMessages(groupId);
    if (messages.isEmpty) return;
    final latest = messages.last;
    group.lastMessage = latest.messageType == 'text' ? latest.text : '[${latest.messageType}]';
    group.lastMessageTime = latest.timestamp;
    await group.save();
  }

  /// Get groups filtered by current project
  List<ChatGroup> getChatGroups() {
    final currentProject = settingsController.currentProject;
    return _groupsBox.values.where((g) {
      if (g.project != null && g.project != currentProject) return false;
      // Filter by role
      if (g.allowedRoles != null && g.allowedRoles!.isNotEmpty) {
        if (!g.allowedRoles!.contains(settingsController.currentUserRole)) return false;
      }
      return true;
    }).toList();
  }

  /// Get offline messages for a specific group
  List<ChatMessage> getMessages(String groupId) {
    final msgs = _messagesBox.values.where((m) => m.groupId == groupId).toList();
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return msgs;
  }

  /// Send a message (saves locally as 'pending', then tries to sync)
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String messageType = 'text',
    String? mediaPath,
    double? lat,
    double? lng,
  }) async {
    final uuid = const Uuid().v4();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final senderName = settingsController.currentUserName ?? 'Noma\'lum';
    final senderId = uid ?? 'pending_auth';
    final message = ChatMessage(
      id: uuid,
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      status: 'pending',
      messageType: messageType,
      mediaPath: mediaPath,
      lat: lat,
      lng: lng,
    );

    await _messagesBox.put(message.id, message);
    await _refreshGroupMetadata(groupId);
    notifyListeners();
    // Kutish rejimida qoladi, uni markaziy CloudSyncService ilova qiladi.
  }

  @override
  void dispose() {
    for (final sub in _chatSubscriptions) {
      sub.cancel();
    }
    _chatSubscriptions.clear();
    super.dispose();
  }
}
