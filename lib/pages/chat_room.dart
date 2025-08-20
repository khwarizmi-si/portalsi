// lib/pages/chat_room.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        // BARU: Tambahkan latar belakang yang menarik
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/chat_bg.png'), // Pastikan Anda punya gambar ini
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: Column(
            children: [
              _ChatAppBar(user: user),
              Expanded(
                child: Consumer<ChatRoomController>(
                  builder: (context, controller, _) {
                    if (controller.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.errorMessage != null) {
                      return Center(child: Text(controller.errorMessage!));
                    }
                    return _MessageList();
                  },
                ),
              ),
              const _MessageInputBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// --- WIDGET INTERNAL DENGAN UI/UX BARU ---
// ================================================================

/// AppBar Kustom untuk Ruang Obrolan
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  const _ChatAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.8),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Online', // Ganti dengan status online asli jika ada
                style: TextStyle(color: Colors.green.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black87),
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
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
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        final bool isMe = message.sender.id == controller.currentUser?.id;

        // Cek apakah pesan sebelumnya dari sender yang sama
        final bool isSameSenderAsPrevious =
            index < controller.messages.length - 1 &&
                controller.messages[index + 1].sender.id == message.sender.id;

        return _MessageBubble(
          message: message,
          isMe: isMe,
          isGrouped: isSameSenderAsPrevious,
        );
      },
    );
  }
}

/// Widget untuk Gelembung Pesan (Bubble Chat)
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isGrouped; // BARU: Untuk grouping pesan

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGrouped,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Theme.of(context).primaryColor : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    final tailAlignment =
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final timestampColor = isMe ? Colors.white70 : Colors.black54;

    return Align(
      alignment: alignment,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        // BARU: Atur margin untuk grouping
        margin: EdgeInsets.only(
          top: isGrouped ? 2.0 : 8.0,
          bottom: 2.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fleksibel agar teks bisa wrap
              Flexible(
                child: Text(
                  message.text ?? "File...",
                  style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              // Waktu dan Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(color: timestampColor, fontSize: 12),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _getStatusIcon(message.status),
                      size: 16,
                      color: message.status == MessageStatus.read
                          ? Colors.blue.shade300
                          : timestampColor,
                    ),
                  ]
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time_rounded;
      case MessageStatus.sent:
        return Icons.done_rounded;
      case MessageStatus.read:
        return Icons.done_all_rounded;
      case MessageStatus.failed:
        return Icons.error_outline_rounded;
      default:
        return Icons.done_rounded;
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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.sentiment_satisfied_alt_outlined,
                  color: Colors.black54),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 14.0),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Ketik pesan...',
                          ),
                          maxLines: 5,
                          minLines: 1,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded,
                          color: Colors.black54),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _textController.text.trim().isEmpty
                    ? Icons.mic_none_outlined
                    : Icons.send_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  chatController.sendMessage(_textController.text);
                  _textController.clear();
                } else {
                  // Fungsi rekam suara
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
