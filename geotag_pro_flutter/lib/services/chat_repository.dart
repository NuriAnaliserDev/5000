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
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final docId = change.doc.id;
          if (_messagesBox.containsKey(docId)) {
            await _messagesBox.delete(docId);
            changed = true;
          }
          continue;
        }

        final doc = change.doc;
        if (!doc.exists) continue;
        final data = doc.data();
        if (data == null) continue;

        final id = (data['id'] as String?)?.isNotEmpty == true ? data['id'] as String : doc.id;
        if (id.isEmpty) continue;

        final senderName = (data['senderName'] as String?) ?? 'Noma\'lum';
        final senderId = (data['senderId'] as String?) ?? 'anon';
        final text = (data['text'] as String?) ?? '';
        final messageType = (data['messageType'] as String?) ?? 'text';
        final mediaUrl = data['mediaUrl'] as String?;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final ts = DateTime.tryParse((data['timestamp'] as String?) ?? '') ?? DateTime.now();
        DateTime? editedAt;
        final eaRaw = data['editedAt'];
        if (eaRaw is String) {
          editedAt = DateTime.tryParse(eaRaw);
        }

        final existing = _messagesBox.get(id);
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
              editedAt: editedAt,
            ),
          );
          changed = true;
          continue;
        }

        var needSave = false;
        if (existing.text != text) {
          existing.text = text;
          needSave = true;
        }
        if (existing.senderName != senderName) {
          existing.senderName = senderName;
          needSave = true;
        }
        if (existing.mediaPath != mediaUrl) {
          existing.mediaPath = mediaUrl;
          needSave = true;
        }
        if (existing.lat != lat) {
          existing.lat = lat;
          needSave = true;
        }
        if (existing.lng != lng) {
          existing.lng = lng;
          needSave = true;
        }
        if (existing.status != 'sent') {
          existing.status = 'sent';
          needSave = true;
        }
        if (editedAt != null &&
            (existing.editedAt == null || !editedAt.isAtSameMomentAs(existing.editedAt!))) {
          existing.editedAt = editedAt;
          needSave = true;
        }
        if (needSave) {
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

  List<ChatGroup> getChatGroups() {
    final currentProject = settingsController.currentProject;
    return _groupsBox.values.where((g) {
      if (g.project != null && g.project != currentProject) return false;
      return true;
    }).toList();
  }

  List<ChatMessage> getMessages(String groupId) {
    final msgs = _messagesBox.values.where((m) => m.groupId == groupId).toList();
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return msgs;
  }

  bool _isMessageMine(ChatMessage m) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return m.senderId == uid;
  }

  /// Matn xabarini tahrirlash. `null` — muvaffaqiyat; aks holda xato matni.
  Future<String?> updateMessageText({
    required String messageId,
    required String newText,
  }) async {
    final t = newText.trim();
    if (t.isEmpty) return 'Bo‘sh xabar yuborib bo‘lmaydi';
    final msg = _messagesBox.get(messageId);
    if (msg == null) return 'Xabar topilmadi';
    if (!_isMessageMine(msg)) return 'Faqat o‘z xabaringizni tahrirlaysiz';
    if (msg.messageType != 'text') return 'Faqat matn xabarlarini tahrirlash mumkin';

    msg.text = t;
    msg.editedAt = DateTime.now();
    await msg.save();

    if (msg.status == 'sent') {
      try {
        await _firestore
            .collection('chat_groups')
            .doc(msg.groupId)
            .collection('messages')
            .doc(msg.id)
            .update({
          'text': t,
          'editedAt': msg.editedAt!.toIso8601String(),
        });
      } catch (e) {
        debugPrint('updateMessageText firestore: $e');
        return 'Bulutga yozilmadi: $e';
      }
    }

    await _refreshGroupMetadata(msg.groupId);
    notifyListeners();
    return null;
  }

  /// Xabarni o‘chirish (mahalliy + yuborilgan bo‘lsa Firestore).
  Future<String?> deleteMessage(String messageId) async {
    final msg = _messagesBox.get(messageId);
    if (msg == null) return null;
    if (!_isMessageMine(msg)) return 'Faqat o‘z xabaringizni o‘chirasiz';

    if (msg.status == 'sent') {
      try {
        await _firestore
            .collection('chat_groups')
            .doc(msg.groupId)
            .collection('messages')
            .doc(msg.id)
            .delete();
      } catch (e) {
        return 'Bulutdan o‘chirilmadi: $e';
      }
    }

    await msg.delete();
    await _refreshGroupMetadata(msg.groupId);
    notifyListeners();
    return null;
  }

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
