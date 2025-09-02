// lib/pages/new_message_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/new_message_controller.dart';
import '../models/user_model.dart';
import 'chat_room.dart';

class NewMessagePage extends StatelessWidget {
  const NewMessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewMessageController(),
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
            'Pesan Baru',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Consumer<NewMessageController>(
                builder: (context, controller, _) {
                  return TextField(
                    onChanged: (value) => controller.filterFollowers(value),
                    decoration: InputDecoration(
                      hintText: 'Cari followers...',
                      prefixIcon: const Icon(Icons.search),
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
            // --- Daftar Followers ---
            Expanded(
              child: Consumer<NewMessageController>(
                builder: (context, controller, _) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.errorMessage != null) {
                    return Center(child: Text(controller.errorMessage!));
                  }
                  if (controller.filteredFollowers.isEmpty) {
                    return const Center(child: Text('Anda belum memiliki followers.'));
                  }
                  return ListView.builder(
                    itemCount: controller.filteredFollowers.length,
                    itemBuilder: (context, index) {
                      final user = controller.filteredFollowers[index];
                      return _FollowerTile(user: user);
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

class _FollowerTile extends StatelessWidget {
  final User user;
  const _FollowerTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
        child: user.profilePictureUrl == null ? Text(user.username.substring(0, 1).toUpperCase()) : null,
      ),
      title: Text(user.fullName ?? user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('@${user.username}'),
      onTap: () {
        // Kembali ke halaman sebelumnya dan buka chat room baru
        Navigator.of(context)
          ..pop()
          ..push(MaterialPageRoute(builder: (_) => ChatRoomPage(user: user)));
      },
    );
  }
}