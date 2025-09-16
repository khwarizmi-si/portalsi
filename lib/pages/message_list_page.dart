// lib/pages/message_list_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/pages/group_chat_room_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/message_list_controller.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'chat_room.dart';
import 'create_group_page.dart';
import 'new_message_page.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFFFA726);

    return ChangeNotifierProvider(
      create: (_) => MessageListController(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade50,
          elevation: 0,
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewMessagePage()),
                );
              },
            ),
            // IconButton(
            //   icon: const Icon(Icons.group_add_outlined,
            //       color: Colors.black87, size: 28),
            //   onPressed: () {
            //     // Navigasi ke halaman buat grup
            //     Navigator.push(context,
            //         MaterialPageRoute(builder: (_) => const CreateGroupPage()));
            //   },
            // ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          controller.filterConversations(value),
                      decoration: InputDecoration(
                        hintText: 'Cari percakapan...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation =
                          controller.filteredConversations[index];
                      // Kirim objek Conversation (bisa User- atau GroupConversation) ke tile
                      return _ConversationTile(
                          conversation: conversation, themeColor: themeColor);
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
/// WIDGET TILE PERCAKAPAN YANG SUDAH FLEKSIBEL
/// ================================================================
class _ConversationTile extends StatelessWidget {
  // Terima abstract class Conversation, bukan lagi model yang spesifik.
  final Conversation conversation;
  final Color themeColor;

  const _ConversationTile(
      {required this.conversation, required this.themeColor});

  String _formatTimestamp(DateTime? dt) {
    // Tambahkan pengecekan null, karena grup baru mungkin tidak punya timestamp
    if (dt == null) return '';

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
    final bool isUnread = conversation.unreadCount > 0;

    // ==== PERUBAHAN UTAMA DI SINI ====
    // Gunakan getter abstrak. Flutter akan otomatis memanggil implementasi
    // yang benar (dari User- atau GroupConversation).
    final String name = conversation.displayName;
    final String message = conversation.lastMessage;
    final String? imageUrl = conversation.displayImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Cek apakah ini percakapan dengan user
          if (conversation is UserConversation) {
            final userChat = conversation as UserConversation;
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatRoomPage(user: userChat.partner)),
            );
          }
          // Cek apakah ini percakapan grup
          else if (conversation is GroupConversation) {
            // Buat variabel lokal untuk memastikan tipe data
            final groupChat = conversation as GroupConversation;

            // ================================================================
            // 👇 HAPUS TANDA COMMENT DARI BARIS INI UNTUK MENGAKTIFKAN NAVIGASI
            // ================================================================
            Navigator.push(
              context,
              MaterialPageRoute(
                // Teruskan objek groupChat ke halaman chat grup
                builder: (_) => GroupChatRoomPage(group: groupChat.group),
              ),
            );
            // ================================================================
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // --- Foto Profil atau Avatar Grup ---
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                // Gunakan imageUrl yang sudah didapat dari getter
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        // Gunakan name yang sudah didapat dari getter
                        name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : '?',
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
                  // 👇 WIDGET HARUS BERADA DI DALAM LIST `children:`
                  children: [
                    Row(
                      children: [
                        // Teks nama
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // Spacer
                        const Spacer(),
                        // Ikon
                        if (conversation is GroupConversation)
                          Icon(
                            Icons.group,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                      ],
                    ),

                    // Di bawah sini Anda akan meletakkan widget Text untuk pesan terakhir
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // --- Waktu dan Indikator Unread ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTimestamp(conversation.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread ? themeColor : Colors.grey.shade500,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isUnread)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: themeColor,
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
      ),
    );
  }
}
