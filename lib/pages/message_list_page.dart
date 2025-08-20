// lib/pages/message_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Pesan',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_outlined,
                  color: Colors.black87, size: 28),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  return TextField(
                    onChanged: (value) => controller.filterConversations(value),
                    decoration: InputDecoration(
                      hintText: 'Cari percakapan...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
            // --- Daftar Percakapan ---
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
                    return const Center(
                        child: Text('Mulai percakapan baru!',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: controller.filteredConversations.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 80,
                      endIndent: 16,
                    ),
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

/// ================================================================
/// WIDGET TILE PERCAKAPAN DENGAN UI/UX BARU
/// ================================================================
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  // Helper untuk format waktu
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(dt); // Contoh: 16:30
    } else if (now.difference(messageDate).inDays == 1) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM/yy').format(dt); // Contoh: 19/08/25
    }
  }

  @override
  Widget build(BuildContext context) {
    final User partner = conversation.partner;
    final bool isUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatRoomPage(user: partner)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // --- Foto Profil ---
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: partner.profilePictureUrl != null &&
                      partner.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(partner.profilePictureUrl!)
                  : null,
              child: partner.profilePictureUrl == null ||
                      partner.profilePictureUrl!.isEmpty
                  ? Text(
                      partner.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // --- Nama dan Pesan Terakhir ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.fullName ?? partner.username,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread ? Colors.black87 : Colors.grey.shade600,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // --- Waktu dan Indikator Unread ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(conversation.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade500,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                if (isUnread)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        conversation.unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                      height: 22), // Placeholder agar alignment tetap sama
              ],
            ),
          ],
        ),
      ),
    );
  }
}
