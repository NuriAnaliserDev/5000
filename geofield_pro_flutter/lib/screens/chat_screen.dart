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

class ChatScreen extends StatefulWidget {
  final String groupId;

  const ChatScreen({super.key, required this.groupId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final loc = context.read<LocationService>().currentPosition;

    await context.read<ChatRepository>().sendMessage(
          groupId: widget.groupId,
          text: text,
          messageType: 'text',
          lat: loc?.latitude,
          lng: loc?.longitude,
        );
    _msgController.clear();

    if (!mounted) return;
    context.read<CloudSyncService>().triggerSync();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // compress slightly
      );
      if (image != null) {
        if (!mounted) return;
        final loc = context.read<LocationService>().currentPosition;
        await context.read<ChatRepository>().sendMessage(
              groupId: widget.groupId,
              text: 'Rasm',
              messageType: 'image',
              mediaPath: image.path,
              lat: loc?.latitude,
              lng: loc?.longitude,
            );

        if (!mounted) return;
        context.read<CloudSyncService>().triggerSync();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatRepo = context.watch<ChatRepository>();
    final messages = chatRepo.getMessages(widget.groupId);
    final groups = chatRepo.getChatGroups();
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surf = Theme.of(context).colorScheme.surface;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: surf,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group?.name ?? 'Aloqa guruhi',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              group?.description ?? 'Guruh holati aniqlanmoqda',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
        backgroundColor: surf,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final myUid = FirebaseAuth.instance.currentUser?.uid;
                final isMe = myUid != null && msg.senderId == myUid;

                return _buildMessageBubble(
                    context, chatRepo, msg, isMe, isDark, primary);
              },
            ),
          ),
          _buildInputArea(isDark, primary),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ChatRepository repo,
    ChatMessage msg,
  ) async {
    final ctrl = TextEditingController(text: msg.text);
    final err = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xabarni tahrirlash'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (!context.mounted || err == null) return;
    final syncErr =
        await repo.updateMessageText(messageId: msg.id, newText: err);
    if (!context.mounted) return;
    if (syncErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(syncErr)));
    } else {
      context.read<CloudSyncService>().triggerSync();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChatRepository repo,
    ChatMessage msg,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xabar o‘chirilsinmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O‘chirish'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final syncErr = await repo.deleteMessage(msg.id);
    if (!context.mounted) return;
    if (syncErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(syncErr)));
    } else {
      context.read<CloudSyncService>().triggerSync();
    }
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatRepository chatRepo,
    ChatMessage msg,
    bool isMe,
    bool isDark,
    Color primary,
  ) {
    final mediaPath = msg.mediaPath;
    final hasRemoteMedia = mediaPath != null && mediaPath.startsWith('http');
    final hasLocalMedia =
        mediaPath != null && !hasRemoteMedia && File(mediaPath).existsSync();
    final canEdit = isMe && msg.messageType == 'text';
    final canDelete = isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: canDelete
            ? () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canEdit)
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Tahrirlash'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showEditDialog(context, chatRepo, msg);
                            },
                          ),
                        ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Colors.red.shade700),
                          title: Text('O‘chirish',
                              style: TextStyle(color: Colors.red.shade700)),
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDelete(context, chatRepo, msg);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF1976D2)
                : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight:
                  isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  msg.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.orangeAccent : Colors.deepOrange,
                  ),
                ),
              if (msg.messageType == 'image' && msg.mediaPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasRemoteMedia
                        ? Image.network(mediaPath)
                        : hasLocalMedia
                            ? Image.file(File(mediaPath))
                            : const Icon(Icons.broken_image,
                                color: Colors.white54, size: 50),
                  ),
                ),
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (msg.lat != null && msg.lng != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    MainTabNavigation.selectTab(
                      context,
                      MainTabNavigation.map,
                      mapLocation: {
                        'lat': msg.lat,
                        'lng': msg.lng,
                      },
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white24
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pin_drop,
                            size: 14, color: isMe ? Colors.white : Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Xaritada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (msg.editedAt != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'tahrirlandi',
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    if (msg.status == 'pending')
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.white70) // Kutish belgisi ⏳
                    else if (msg.status == 'sent')
                      const Icon(Icons.done_all, size: 14, color: Colors.white)
                    else if (msg.status == 'error')
                      const Icon(Icons.error_outline,
                          size: 12, color: Colors.redAccent)
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: primary),
            onPressed: () => _pickImage(ImageSource.camera),
            iconSize: 22,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          ),
          IconButton(
            icon: Icon(Icons.photo, color: primary),
            onPressed: () => _pickImage(ImageSource.gallery),
            iconSize: 22,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          ),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: 'Xabar yozish...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade200,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              iconSize: 20,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),
          ),
        ],
      ),
    );
  }
}
