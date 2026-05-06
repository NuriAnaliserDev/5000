part of '../chat_screen.dart';

class _ChatScreenState extends State<ChatScreen>
    with ChatScreenFields, ChatScreenLogicMixin, ChatScreenUiMixin {
  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
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
}
