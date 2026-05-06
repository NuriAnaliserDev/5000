part of '../chat_screen.dart';

mixin ChatScreenLogicMixin on ChatScreenFields {
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
        imageQuality: 70,
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
}
