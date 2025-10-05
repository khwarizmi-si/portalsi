// lib/pages/group_chat_room_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:portal_si/controllers/group_chat_controller.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';
import '../utils/slide_right_route.dart';
import '../widgets/add_members_bottom_sheet.dart';
import 'edit_group_page.dart';
import 'group_info_page.dart';
import 'group_members_page.dart';

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

class _GroupChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Group group;

  const _GroupChatAppBar({required this.group});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupChatRoomController>(
      builder: (context, controller, child) {
        final member1 = controller.appBarMembers.isNotEmpty ? controller.appBarMembers[0] : null;
        final member2 = controller.appBarMembers.length > 1 ? controller.appBarMembers[1] : null;

        return Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // [PERUBAHAN 1] Bungkus avatar dengan GestureDetector
                GestureDetector(
                  onTap: () {
                    // Navigasi ke halaman anggota grup
                    Navigator.push(
                      context,
                      SlideRightRoute(page: GroupMembersPage(groupId: group.id, isCurrentUserAdmin: controller.isCurrentUserAdmin,)),
                    );
                  },
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (member2 != null && member2.profilePictureUrl != null)
                          Positioned(
                              right: 0,
                              child: CircleAvatar(radius: 15, backgroundImage: NetworkImage(member2.profilePictureUrl!))
                          ),
                        if (member1 != null && member1.profilePictureUrl != null)
                          Positioned(
                              left: 0,
                              child: CircleAvatar(radius: 15, backgroundImage: NetworkImage(member1.profilePictureUrl!))
                          ),
                        if (member1 == null && member2 == null)
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(group.name.substring(0,1).toUpperCase(), style: const TextStyle(fontSize: 20, color: Colors.grey)),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // [PERUBAHAN 2] Bungkus nama grup dengan Expanded dan GestureDetector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigasi ke halaman info grup
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: GroupInfoPage(
                            group: group,
                            controller: controller, //This line has been changed
                            isCurrentUserAdmin: controller.isCurrentUserAdmin,
                          ),
                        ),
                      );
                    },
                    // Beri warna transparan agar area klik mencakup seluruh area
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (group.memberCount != null && group.memberCount! > 0)
                            Text(
                              '${group.memberCount} anggota',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tombol menu titik tiga (tidak ada perubahan)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.black.withOpacity(0.7)),
                  onSelected: (value) {
                    if (value == 'reload') {
                      controller.reloadMessages();
                    } else if (value == 'clear_cache') {
                      controller.clearCacheAndReload();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cache untuk grup "${group.name}" telah dihapus.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'reload', child: Text('Muat ulang percakapan')),
                  //   const PopupMenuDivider(),
                  //   const PopupMenuItem<String>(
                  //     value: 'clear_cache',
                  //     child: Row(
                  //       children: [
                  //         Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  //         SizedBox(width: 12),
                  //         Text('Hapus Cache (Debug)'),
                  //       ],
                  //     ),
                  //   ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

// Widget utama untuk UI
class GroupChatRoomView extends StatefulWidget {
  const GroupChatRoomView({super.key});

  @override
  State<GroupChatRoomView> createState() => _GroupChatRoomViewState();
}

class _GroupChatRoomViewState extends State<GroupChatRoomView> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  SlidableController? _slidableController;
  final FocusNode _messageFocusNode = FocusNode();
  bool _showMentionList = false;
  List<User> _mentionSuggestions = [];
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    // [MODIFIKASI] Tambahkan listener ke message controller
    _messageController.addListener(_onTextChanged);
    SecureStorage.getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
    _slidableController = SlidableController(this);
  }

  @override
  void dispose() {
    // [MODIFIKASI] Hapus listener
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _slidableController?.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.base.offset;

    // Jika teks kosong atau cursor tidak valid, sembunyikan daftar
    if (text.isEmpty || cursorPos < 0) {
      if (_showMentionList) {
        setState(() => _showMentionList = false);
      }
      return;
    }

    // Cari posisi '@' terakhir sebelum posisi cursor
    final lastAtPos = text.lastIndexOf('@', cursorPos - 1);

    if (lastAtPos != -1) {
      // Pastikan tidak ada spasi antara '@' dan cursor
      final substringAfterAt = text.substring(lastAtPos, cursorPos);
      if (!substringAfterAt.contains(RegExp(r'\s'))) {
        final query = substringAfterAt.substring(1);
        final allMembers = context.read<GroupChatRoomController>().membersMap.values.toList();

        setState(() {
          _mentionQuery = query;
          _mentionSuggestions = allMembers.where((user) {
            final queryLower = query.toLowerCase();
            final usernameLower = user.username.toLowerCase();
            final fullNameLower = (user.fullName ?? '').toLowerCase();
            return usernameLower.contains(queryLower) || fullNameLower.contains(queryLower);
          }).toList();
          _showMentionList = _mentionSuggestions.isNotEmpty;
        });
        return;
      }
    }

    // Jika tidak dalam mode mention, sembunyikan daftar
    if (_showMentionList) {
      setState(() => _showMentionList = false);
    }
  }

  // [BARU] Method yang dipanggil saat pengguna memilih user dari daftar
  void _onMentionSelected(User user) {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.base.offset;

    final lastAtPos = text.lastIndexOf('@', cursorPos - 1);
    if (lastAtPos == -1) return;

    final textBefore = text.substring(0, lastAtPos);
    final mention = '@${user.username} '; // Tambahkan spasi setelah username
    final textAfter = text.substring(cursorPos);

    final newText = textBefore + mention + textAfter;

    _messageController.text = newText;
    // Pindahkan cursor ke akhir username yang baru disisipkan
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: lastAtPos + mention.length),
    );

    setState(() {
      _showMentionList = false;
      _mentionSuggestions = [];
    });
  }

  // [BARU] Widget untuk membangun UI daftar mention
  Widget _buildMentionList() {
    if (!_showMentionList || _mentionSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200, // Batasi tinggi
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        itemCount: _mentionSuggestions.length,
        itemBuilder: (context, index) {
          final user = _mentionSuggestions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePictureUrl != null
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(user.fullName ?? user.username),
            subtitle: Text('@${user.username}'),
            onTap: () => _onMentionSelected(user),
          );
        },
      ),
    );
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

    // [DIHAPUS] Variabel member1 dan member2 tidak lagi dibutuhkan di sini
    // final member1 = ...
    // final member2 = ...

    return Scaffold(
      backgroundColor: Colors.white,
      // [PERUBAHAN 1] Properti appBar dihapus dari Scaffold
      // appBar: AppBar( ... ),

      // [PERUBAHAN 2] Body diubah menjadi Column yang berisi AppBar kustom dan Expanded ListView
      body: Column(
        children: [
          // AppBar kustom kita letakkan di sini agar tidak ikut ter-scroll
          _GroupChatAppBar(group: group),

          // ListView sekarang dibungkus dengan Expanded agar mengisi sisa ruang
          Expanded(
            child: ListView.builder(
              // ... sisa kode ListView.builder Anda tidak perlu diubah ...
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: controller.messages.length + 1,
              itemBuilder: (context, index) {
                if (index == controller.messages.length) {
                  return _buildGroupProfileHeader(group);
                }

                final message = controller.messages[index];
                final isMe = message.sender.id == controller.currentUserId;
                final senderDetails = controller.membersMap[message.sender.id];

                bool showDateSeparator = false;

                // Jika ini adalah pesan paling tua di list, selalu tampilkan penanda
                if (index == controller.messages.length - 1) {
                  showDateSeparator = true;
                } else {
                  // Bandingkan tanggal pesan ini dengan pesan yang lebih tua (index + 1)
                  final olderMessage = controller.messages[index + 1];
                  final currentCategory = _getCategoryStringForDate(message.sentAt.toLocal());
                  final olderCategory = _getCategoryStringForDate(olderMessage.sentAt.toLocal());
                  // Jika kategori berbeda, tampilkan penanda
                  if (currentCategory != olderCategory) {
                    showDateSeparator = true;
                  }
                }

                final isLastMessage = index == controller.messages.length - 1;
                final isSenderDifferentFromNext = !isLastMessage && controller.messages[index + 1].sender.id != message.sender.id;

                bool showSenderName = !isMe && (isLastMessage || isSenderDifferentFromNext);

                return Column(
                  children: [Slidable(
                    key: ValueKey(message.id),
                    closeOnScroll: true,
                    startActionPane: ActionPane(
                      motion: const BehindMotion(),
                      extentRatio: 0.20,
                      openThreshold: 0.10,
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            controller.setRepliedToMessage(message);
                            Slidable.of(context)?.close();
                          },
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.green,
                          icon: Icons.reply,
                          label: 'Balas',
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.reply),
                                    title: const Text('Balas Pesan'),
                                    onTap: () {
                                      controller.setRepliedToMessage(message);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: _MessageBubble(
                        message: message,
                        isMe: isMe,
                        showSenderName: showSenderName,
                        sender: senderDetails,
                      ),
                    ),
                  ),
                    if (showDateSeparator)
                      _buildDateSeparator(_getCategoryStringForDate(message.sentAt.toLocal())),
                ],
                );
              },
            ),
          ),
          _buildMentionList(), // Daftar mention akan muncul di sini saat aktif
          if (controller.isReloading) const LinearProgressIndicator(),
          _buildMessageInput(context, controller),
        ],
      ),
    );
  }

  Widget _buildGroupProfileHeader(Group group) {
    // Ambil controller untuk memeriksa status admin
    final controller = context.read<GroupChatRoomController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
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

          // Tampilkan tulisan "Ubah nama dan gambar" HANYA JIKA BUKAN ADMIN
          if (controller.isCurrentUserAdmin)
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push(
                  context,
                  SlideRightRoute(
                    // Sekarang 'group' terdefinisi karena berasal dari parameter metode
                    page: EditGroupPage(group: group),
                  ),
                );

                if (result == true && mounted) {
                  controller.reloadMessages();
                }
              },
              child: Text('Ubah nama dan gambar', style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
            ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.info_outline, 'Info\nGrup', () {
                HapticFeedback.lightImpact();
                // --- [MODIFIKASI NAVIGASI DI SINI] ---
                Navigator.push(
                  context,
                  SlideRightRoute(
                    page: GroupInfoPage(
                      group: group,
                      controller: controller, // This line is modified
                      // Teruskan status admin ke halaman berikutnya
                      isCurrentUserAdmin: controller.isCurrentUserAdmin,
                    ),
                  ),
                );
                // --- BATAS MODIFIKASI ---
              }),

              // Tampilkan tombol "Tambahkan orang" HANYA JIKA BUKAN ADMIN
              if (controller.isCurrentUserAdmin)
                _buildActionIcon(Icons.person_add_alt_1, 'Tambahkan\norang', () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddMembersBottomSheet(groupId: group.id),
                  ).then((result) {
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

  Widget _buildDateSeparator(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Biru muda yang lembut
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // [BARU] Fungsi untuk mendapatkan kategori tanggal dalam bentuk String
  String _getCategoryStringForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final differenceInDays = today.difference(messageDate).inDays;

    if (differenceInDays == 0) {
      return 'Hari Ini';
    } else if (differenceInDays == 1) {
      return 'Kemarin';
    } else if (differenceInDays <= 7) {
      return '7 Hari Terakhir';
    } else if (differenceInDays <= 30) {
      return '30 Hari Terakhir';
    } else {
      return 'Lebih Lama';
    }
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
    final repliedToMessage = controller.repliedToMessage;
    // Tentukan apakah tombol Send aktif (ada teks ATAU ada pesan yang dibalas)
    final bool isActive = _messageController.text.isNotEmpty || repliedToMessage != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border(
        //   top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        // ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (repliedToMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: repliedToMessage.sender.id == controller.currentUserId ? Colors.orange.shade800 : _MessageBubble.getSenderColor(repliedToMessage.sender.id.toString()), width: 4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repliedToMessage.sender.fullName ?? repliedToMessage.sender.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: repliedToMessage.sender.id == controller.currentUserId ? Colors.orange.shade800 : _MessageBubble.getSenderColor(repliedToMessage.sender.id.toString()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          repliedToMessage.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => controller.setRepliedToMessage(null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController, // Listener sudah dipasang di initState
                  focusNode: _messageFocusNode,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _messageController.text.isNotEmpty
                        ? null
                        : IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        // Tambahkan fungsionalitas lampiran di sini
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (isActive) {
                    if (_messageController.text.trim().isNotEmpty) {
                      controller.sendMessage(_messageController.text);
                      _messageController.clear();
                    } else if (repliedToMessage != null) {
                      controller.sendMessage('');
                    }
                  }
                  // Panggil setState setelah aksi untuk memastikan UI update
                  if (mounted) setState(() {});
                },

                // ✨ MODIFIKASI: Ganti CircleAvatar dengan Container berdekorasi gradient
                child: Container(
                  width: 48, // Radius * 2
                  height: 48, // Radius * 2
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // KONDISI UTAMA UNTUK GRADIENT
                    gradient: isActive
                        ? const LinearGradient(
                      colors: [
                        Color(0xFFFF8D42), // Warna Orange
                        Color(0xFFFFC088), // Warna Orange Lebih Terang
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null, // Jika tidak aktif, gradient null (diganti dengan warna solid)

                    color: isActive
                        ? null // Jika aktif, warna diurus oleh gradient
                        : Colors.grey.shade300, // Warna abu-abu saat tidak aktif
                  ),
                  child: Icon(
                    Icons.send,
                    color: isActive ? Colors.white : Colors.grey.shade600, // Warna ikon menyesuaikan
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMe;
  final bool showSenderName;
  final User? sender;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
    this.sender,
  });

  String _formatTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    if (messageDay.isAtSameMomentAs(today)) {
      return DateFormat.Hm().format(localDateTime);
    } else if (messageDay.isAtSameMomentAs(yesterday)) {
      return 'Kemarin, ${DateFormat.Hm().format(localDateTime)}';
    } else if (now.difference(messageDay).inDays < 7) {
      return DateFormat('EEEE, Hm').format(localDateTime);
    } else {
      return DateFormat('d MMMM yyyy, Hm').format(localDateTime);
    }
  }

  // Tambahkan metode statis ini untuk mendapatkan warna pengirim
  static Color getSenderColor(String senderId) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];
    return colors[senderId.hashCode % colors.length];
  }

  Color _getSenderColor(String senderId) {
    return getSenderColor(senderId);
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
                      sender!.fullName ?? sender!.username,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(message.sender.id.toString()),
                      ),
                    ),
                  ],
                ),
              ),
            // Tambahkan tampilan pesan yang dibalas di sini
            if (message.repliedTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(

                  color: isMe ? Color(0xFFFFEDD7) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(
                    color: _getSenderColor(message.repliedTo!.sender.id.toString()),
                    width: 4,
                  )),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.repliedTo!.sender.fullName ?? message.repliedTo!.sender.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(message.repliedTo!.sender.id.toString()),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.repliedTo!.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            // Gelembung pesan utama
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF8D42) : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(message.content,
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                          height: 1.3)),
                  const SizedBox(height: 4),
                  Text(_formatTime(message.sentAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
