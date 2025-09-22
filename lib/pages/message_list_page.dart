// lib/pages/message_list_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/pages/group_chat_room_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/message_list_controller.dart';
import '../models/chat.dart';
import 'chat_room.dart';
import 'create_group_page.dart';
import 'new_message_page.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // [MODIFIKASI] Hapus themeColor dari sini, kita definisikan di dalam tile
    // final themeColor = const Color(0xFFFFA726);

    return ChangeNotifierProvider(
      create: (_) => MessageListController(),
      child: Scaffold(
        backgroundColor: Colors.white, // <-- [UBAH] Latar belakang utama jadi putih
        appBar: AppBar(
          backgroundColor: Colors.white, // <-- [UBAH] Warna AppBar
          elevation: 0,
          // Hapus tombol back jika ini adalah halaman utama di tab
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
          //   onPressed: () => Navigator.of(context).pop(),
          // ),
          title: const Text(
            'Pesan',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24), // Sedikit perbesar
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, // <-- [UBAH] Ganti ikon
                  color: Colors.black87, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewMessagePage()),
                );
              },
            ),
            // Hapus tombol group jika tidak ada di desain
            IconButton(
              icon: const Icon(Icons.group_add_outlined,
                  color: Colors.black87, size: 28),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateGroupPage()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  return TextField( // <-- [UBAH] Sederhanakan search bar
                    onChanged: (value) =>
                        controller.filterConversations(value),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade600),
                      // [TAMBAHAN] Tambahkan tombol filter
                      suffixIcon: IconButton(
                        icon: Icon(Icons.tune_rounded, color: Colors.grey.shade600),
                        onPressed: () {
                          // TODO: Tambahkan logika untuk filter
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100, // <-- [UBAH] Warna search bar
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder( // <-- [UBAH] Tambahkan border
                        borderRadius: BorderRadius.circular(30),
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
                    return const Center(
                        child: Text('Mulai percakapan baru!',
                            style:
                            TextStyle(fontSize: 16, color: Colors.grey)));
                  }
                  return ListView.builder(
                    // [UBAH] Hapus padding horizontal dari ListView
                    padding: const EdgeInsets.only(bottom: 100),
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

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  // [UBAH] Hapus themeColor dari constructor
  const _ConversationTile({required this.conversation});

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    // Logika format waktu bisa disesuaikan agar lebih mirip gambar
    // Contoh: '1 jam', '5 jam'
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inHours < 24 && dt.day == now.day) {
      if (difference.inMinutes < 60) return '${difference.inMinutes} mnt';
      return '${difference.inHours} jam';
    }
    return DateFormat('dd/MM/yy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = conversation.unreadCount > 0;
    final String name = conversation.displayName;
    final String message = conversation.lastMessage;
    final String? imageUrl = conversation.displayImageUrl;

    return InkWell( // <-- [UBAH] Bungkus dengan InkWell
      onTap: () {
        if (conversation is UserConversation) {
          final userChat = conversation as UserConversation;
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatRoomPage(user: userChat.partner)),
          );
        } else if (conversation is GroupConversation) {
          final groupChat = conversation as GroupConversation;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatRoomPage(group: groupChat.group),
            ),
          );
        }
      },
      child: Padding(
        // [TAMBAHAN] Tambahkan padding horizontal di sini
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Text(
                name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add a small gap
                      const SizedBox(width: 6),
                      // If it's a group, show the group icon
                      if (conversation is GroupConversation)
                        Icon(
                          Icons.group,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatTimestamp(conversation.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}