// lib/pages/message_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl untuk format waktu
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

  // Helper untuk format waktu
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(dt); // Contoh: 16:30
    } else {
      return DateFormat('dd/MM/yy').format(dt); // Contoh: 19/08/25
    }
  }

  @override
  Widget build(BuildContext context) {
    final User partner = conversation.partner;
    final bool isUnread = conversation.unreadCount > 0;
    final fontWeight = isUnread ? FontWeight.bold : FontWeight.normal;
    final textColor = isUnread ? Colors.black : Colors.grey.shade600;

    return InkWell(
      onTap: () {
        // Navigasi dengan objek User yang datanya mungkin belum lengkap.
        // Halaman ChatRoomPage disarankan untuk memuat data lengkap user ini.
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatRoomPage(user: partner)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: partner.profilePictureUrl != null &&
                      partner.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(partner.profilePictureUrl!)
                  : null,
              child: partner.profilePictureUrl == null ||
                      partner.profilePictureUrl!.isEmpty
                  ? Text(partner.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Tampilkan username karena full_name belum ada dari API chat-list
                    partner.username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: fontWeight,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${conversation.lastMessage} ・ ${_formatTimestamp(conversation.timestamp)}',
                    style: TextStyle(fontSize: 14, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) // Tampilkan badge jika belum dibaca
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color:
                      Colors.deepPurple, // Bisa disesuaikan dengan warna tema
                  shape: BoxShape.circle,
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
