// lib/message_list_page.dart

import 'package:flutter/material.dart';
import 'chat_room.dart';
import '../models/chat.dart';

// Asumsi data pengguna ini sudah ada
final List<ChatUser> _allUsers = [
  ChatUser(
      id: '1',
      name: "Rizky Herdiansyah",
      username: "r_herdians",
      imageUrl: "assets/avatars/avatar1.png"),
  ChatUser(
      id: '2',
      name: "Siti Aminah",
      username: "siti_a",
      imageUrl: "assets/avatars/avatar2.png"),
  ChatUser(
      id: '3',
      name: "Budi Santoso",
      username: "budisan",
      imageUrl: "assets/avatars/avatar3.png"),
  ChatUser(
      id: '4',
      name: "Khansa Syahidah",
      username: "kiantza",
      imageUrl: "assets/avatars/avatar4.png"),
  ChatUser(id: '5', name: "Agus Wijaya", username: "agus_w", imageUrl: null),
];

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _allUsers;
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    // ... (fungsi filter tetap sama)
  }

  void _navigateToChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatRoomPage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ganti warna latar belakang utama
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        // Gunakan warna putih untuk AppBar agar kontras
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Pesan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                // Latar search bar dibuat lebih netral
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return InkWell(
                  onTap: () => _navigateToChat(user),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: user.imageUrl != null
                              ? AssetImage(user.imageUrl!)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Pengguna',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pesan terakhir...',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }
}
