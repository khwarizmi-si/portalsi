// lib/pages/group_chat_room_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portal_si/controllers/group_chat_controller.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';
import '../widgets/add_members_bottom_sheet.dart';

// Halaman utama yang menyediakan controller
class GroupChatRoomPage extends StatelessWidget {
  final Group group;
  const GroupChatRoomPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupChatRoomController(group: group),
      child: const GroupChatRoomView(),
    );
  }
}

// Widget utama untuk UI
class GroupChatRoomView extends StatefulWidget {
  const GroupChatRoomView({super.key});

  @override
  State<GroupChatRoomView> createState() => _GroupChatRoomViewState();
}

class _GroupChatRoomViewState extends State<GroupChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    SecureStorage.getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<GroupChatRoomController>().loadMoreMessages();
    }
  }

  void _sendMessage(GroupChatRoomController controller) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      controller.sendMessage(text);
      _messageController.clear();
    }
  }

  // [DIHAPUS] Fungsi _getDateSeparatorText dan _isSameDay dihapus karena tidak lagi digunakan

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GroupChatRoomController>();
    final group = controller.group;
    final member1 = controller.appBarMembers.isNotEmpty ? controller.appBarMembers[0] : null;
    final member2 = controller.appBarMembers.length > 1 ? controller.appBarMembers[1] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 45,
              height: 25,
              child: Stack(
                children: [
                  if (member2 != null)
                    Positioned(right: 0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(member2.profilePictureUrl ?? ''))),
                  if (member1 != null)
                    Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(member1.profilePictureUrl ?? ''))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(group.name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) {
              if (value == 'reload') {
                controller.reloadMessages();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'reload',
                child: Text('Muat ulang percakapan'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.messages.length + 2,
              itemBuilder: (context, index) {
                // Item untuk header & tombol load more
                if (index == controller.messages.length + 1) {
                  return _buildGroupProfileHeader(group);
                }
                if (index == controller.messages.length) {
                  return _buildLoadMoreButton(controller);
                }

                final message = controller.messages[index];
                final isMe = message.sender.id == _currentUserId;
                final senderDetails = controller.membersMap[message.sender.id];

                // --- [PERBAIKAN UTAMA] Logika pembatas tanggal dihapus ---
                bool showSenderName = !isMe && (index == 0 || controller.messages[index - 1].sender.id != message.sender.id);

                // Langsung kembalikan _MessageBubble tanpa Column
                return _MessageBubble(
                  message: message,
                  isMe: isMe,
                  showSenderName: showSenderName,
                  sender: senderDetails,
                );
              },
            ),
          ),
          if (controller.isReloading) const LinearProgressIndicator(),
          _buildMessageInput(context, controller),
        ],
      ),
    );
  }

  Widget _buildGroupProfileHeader(Group group) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          // --- [PERUBAHAN] Tampilkan avatar grup ---
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? NetworkImage(group.avatarUrl!)
                : null,
            child: (group.avatarUrl == null || group.avatarUrl!.isEmpty)
                ? Icon(Icons.group, size: 50, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(height: 16),
          Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text('Ubah nama dan gambar', style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.info_outline, 'Info\nGrup', () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fitur ini akan segera hadir..'),
                    backgroundColor: Colors.blueAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
              _buildActionIcon(Icons.person_add_alt_1, 'Tambahkan\norang', () {
                // Panggil BottomSheet saat ikon diklik
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddMembersBottomSheet(groupId: group.id),
                ).then((result) {
                  // Jika bottom sheet ditutup & mengembalikan 'true',
                  // refresh data anggota
                  if (result == true) {
                    context.read<GroupChatRoomController>().fetchGroupMembers();
                  }
                });
              }),
              _buildActionIcon(Icons.color_lens, 'Tema\nPercakapan', () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fitur ini akan segera hadir..'),
                    backgroundColor: Colors.blueAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap, // Gunakan callback yang diterima
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context, GroupChatRoomController controller) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Pesan...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: 5, minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Gunakan Container untuk dekorasi (gradient dan border radius)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade600,
                  Colors.orange.shade800,
                ],
                // Anda bisa menambahkan begin dan end untuk mengatur arah gradien
                // begin: Alignment.topLeft,
                // end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent, // Buat Material transparan
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24), // Agar efek ripple sesuai bentuk
                onTap: () => _sendMessage(controller),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildLoadMoreButton(GroupChatRoomController controller) {
    // Jika tidak ada lagi halaman untuk dimuat, jangan tampilkan apa-apa
    if (!controller.hasMorePagesToLoad) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: controller.isLoadingMore
          ? const CircularProgressIndicator()
          : OutlinedButton(
        onPressed: () {
          // Panggil fungsi untuk memuat halaman sebelumnya
          controller.loadMoreMessages();
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Muat pesan sebelumnya',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMe;
  final bool showSenderName;
  final User? sender;

  const _MessageBubble({required this.message, required this.isMe, required this.showSenderName, this.sender});

  String _formatTime(DateTime dateTime) {
    return DateFormat.Hm().format(dateTime);
  }

  Color _getSenderColor(String senderId) {
    final colors = [
      Colors.blue.shade600, Colors.green.shade600, Colors.orange.shade600,
      Colors.purple.shade600, Colors.teal.shade600, Colors.indigo.shade600,
    ];
    return colors[senderId.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 2, bottom: 2, left: isMe ? 64 : 16, right: isMe ? 16 : 64),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && !isMe && sender != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: sender!.profilePictureUrl != null
                          ? NetworkImage(sender!.profilePictureUrl!)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sender!.fullName ?? sender!.username, // Prioritaskan nama lengkap
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(message.sender.id.toString()),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFFFF8D42) : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(_formatTime(message.sentAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}