// lib/pages/message_list_page.dart (FINAL & FIXED)

import 'package:flutter/material.dart';
import 'package:portal_si/pages/group_chat_room_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../components/verified_badge.dart';
import '../controllers/message_list_controller.dart';
import '../models/chat.dart';
import 'chat_room.dart';
import 'create_group_page.dart';
import 'new_message_page.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: const [
            Text(
              'Pesan',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageListController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: null,
        // --- [PERBAIKAN 1: MENGGUNAKAN SIZEDBOX UNTUK UKURAN KUSTOM] ---
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Tombol atas dengan ukuran kustom 48x48
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: 'fab_new_message',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewMessagePage()),
                  );
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4.0,
                tooltip: 'Tulis Pesan Baru',
                child: const Icon(Icons.edit_outlined, size: 24),
              ),
            ),
            const SizedBox(height: 16),
            // Tombol bawah dengan ukuran kustom 65x65
            SizedBox(
              width: 65,
              height: 65,
              child: FloatingActionButton(
                heroTag: 'fab_new_group',
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateGroupPage()));
                },
                backgroundColor: const Color(0xFFE0AD05),
                elevation: 4.0,
                tooltip: 'Buat Grup Baru',
                child: const Icon(Icons.group_add_outlined, color: Colors.white, size: 26),
              ),

            ),
          ],
        ),
        body: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Consumer<MessageListController>(
                builder: (context, controller, _) {
                  return TextField(
                    onChanged: (value) =>
                        controller.filterConversations(value),
                    decoration: InputDecoration(
                      hintText: 'Cari...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
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
                  return RefreshIndicator(
                    onRefresh: () => controller.fetchConversations(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: controller.filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conversation =
                        controller.filteredConversations[index];
                        return _ConversationTile(
                          conversation: conversation,
                          controller: controller,
                        );
                      },
                    ),
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
  final MessageListController controller;

  const _ConversationTile({
    required this.conversation,
    required this.controller,
  });

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
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

    // --- [PERBAIKAN 2: LOGIKA isVerified] ---
    bool isVerified = false;
    // Lakukan pengecekan tipe sebelum mengakses properti
    if (conversation is UserConversation) {
      // Kita cast secara eksplisit untuk memastikan tipe data benar
      isVerified = (conversation as UserConversation).isPartnerVerified;
    }

    return InkWell(
      onTap: () async {
        Widget page;
        if (conversation is UserConversation) {
          page = ChatRoomPage(user: (conversation as UserConversation).partner);
        } else if (conversation is GroupConversation) {
          page = GroupChatRoomPage(group: (conversation as GroupConversation).group);
        } else {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

        if (context.mounted) {
          debugPrint("Kembali ke daftar pesan, memuat ulang data...");
          controller.fetchConversations();
        }
      },
      child: Padding(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            if (isVerified)
                              const SizedBox(width: 6),
                            if (isVerified)
                              VerifiedBadge(
                                size: 16,
                                profilePictureUrl: conversation.displayImageUrl,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (conversation is GroupConversation)
                        Icon(
                          Icons.group,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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