import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_room_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';

class ChatRoomPage extends StatelessWidget {
  final User user;
  const ChatRoomPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatRoomController(recipient: user),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _ChatAppBar(user: user),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatRoomController>(
                builder: (context, controller, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.errorMessage != null) {
                    return Center(child: Text(controller.errorMessage!));
                  }
                  return _MessageList(); // Tidak perlu passing messages lagi
                },
              ),
            ),
            const _MessageInputBar(),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET INTERNAL ---

/// AppBar Kustom untuk Ruang Obrolan
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  const _ChatAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: user.profilePictureUrl != null &&
                    user.profilePictureUrl!.isNotEmpty
                ? NetworkImage(user.profilePictureUrl!)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName ?? user.username,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Online', // Ganti dengan status online asli jika ada
                style: TextStyle(color: Colors.green[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Widget untuk Daftar Pesan
class _MessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatRoomController>();

    return ListView.builder(
      reverse: true, // Membuat list mulai dari bawah dan scroll ke atas
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        final bool isMe = message.sender.id == controller.currentUser?.id;

        return _MessageBubble(message: message, isMe: isMe);
      },
    );
  }
}

/// Widget untuk Gelembung Pesan (Bubble Chat)
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Colors.black87 : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text ?? "File...",
                style: TextStyle(color: textColor, fontSize: 15, height: 1.3)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      color: textColor.withOpacity(0.6), fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? Colors.blue
                        : textColor.withOpacity(0.6),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.watch_later_outlined;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.done;
    }
  }
}

/// Widget untuk Input Bar di Bagian Bawah
class _MessageInputBar extends StatefulWidget {
  const _MessageInputBar();

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  final TextEditingController _textController = TextEditingController();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) {
        setState(() {
          _showSendButton = _textController.text.trim().isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.read<ChatRoomController>();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.add, color: Colors.black87),
                onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Kirim pesan...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _showSendButton
                  ? IconButton(
                      key: const ValueKey('send_button'),
                      icon: Icon(Icons.send,
                          color: Theme.of(context).primaryColor),
                      onPressed: () {
                        chatController.sendMessage(_textController.text);
                        _textController.clear();
                      },
                    )
                  : IconButton(
                      key: const ValueKey('mic_button'),
                      icon: const Icon(Icons.mic, color: Colors.black87),
                      onPressed: () {
                        /* TODO: Panggil controller.startRecording() */
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
