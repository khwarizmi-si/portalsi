import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/message_list_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'chat_room.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageListController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Pesan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_outlined,
                  color: Colors.black, size: 28),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  // Hubungkan TextField ke metode filter di controller
                  return TextField(
                    onChanged: (value) => controller.filterConversations(value),
                    decoration: InputDecoration(
                      hintText: 'Cari',
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Daftar Percakapan
            Expanded(
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.errorMessage != null) {
                    return Center(child: Text(controller.errorMessage!));
                  }
                  if (controller.filteredConversations.isEmpty) {
                    return const Center(child: Text('Tidak ada pesan.'));
                  }
                  return ListView.builder(
                    itemCount: controller.filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation =
                          controller.filteredConversations[index];
                      return _ConversationTile(conversation: conversation);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget untuk satu baris percakapan
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    // Akses data dari `conversation.user`
    final User user = conversation.user;

    final bool isUnread = !conversation.isRead;
    final fontWeight = isUnread ? FontWeight.bold : FontWeight.normal;
    final textColor = isUnread ? Colors.black : Colors.grey.shade600;

    return InkWell(
      onTap: () {
        // Navigasi ke ruang obrolan dengan mengirim objek User yang benar
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatRoomPage(user: user)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.profilePictureUrl != null &&
                      user.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: fontWeight,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${conversation.lastMessage} ・ ${conversation.lastMessageTime}',
                    style: TextStyle(fontSize: 14, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon:
                  Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
