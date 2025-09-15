// lib/pages/create_group_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:portal_si/models/group_model.dart';
import 'package:portal_si/pages/group_chat_room_page.dart';
import 'package:provider/provider.dart';
import '../controllers/create_group_controller.dart';
import '../models/user_model.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGroupController(),
      child: Consumer<CreateGroupController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Grup Baru',
                  style: TextStyle(color: Colors.black)),
              actions: [
                TextButton(
                  onPressed: controller.isCreatingGroup ||
                          controller.groupNameController.text.isEmpty
                      ? null
                      : () async {
                          // Panggil method createGroup dari controller
                          final newGroupData = await controller.createGroup();

                          // Jika berhasil dan widget masih ada
                          if (newGroupData != null && context.mounted) {
                            // Buat objek Group dari data yang dikembalikan
                            final newGroup = Group.fromJson(newGroupData);

                            // Tampilkan notifikasi
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Grup berhasil dibuat!'),
                                  backgroundColor: Colors.green),
                            );

                            // Gantikan halaman saat ini dengan halaman chat grup yang baru
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (_) =>
                                  GroupChatRoomPage(group: newGroup),
                            ));
                          }
                        },
                  child: controller.isCreatingGroup
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Buat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(context, controller),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: controller.filterFollowers,
                    decoration: InputDecoration(
                      hintText: 'Cari orang untuk ditambahkan...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                  child: Text(
                      "Pilih Anggota (${controller.selectedUsers.length})",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  child: _buildUserList(controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // [PERUBAHAN TOTAL] Widget header baru untuk cover dan avatar
  Widget _buildGroupHeader(
      BuildContext context, CreateGroupController controller) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // Area untuk Cover Image
        GestureDetector(
          onTap: () => controller.pickImage(false), // isAvatar = false
          child: Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: controller.coverFile != null
                ? Image.file(controller.coverFile!, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey),
                      SizedBox(height: 4),
                      Text("Tambah foto cover group",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
        // Area untuk Avatar, Nama Grup, dan Deskripsi
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => controller.pickImage(true), // isAvatar = true
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: controller.avatarFile != null
                        ? FileImage(controller.avatarFile!)
                        : null,
                    child: controller.avatarFile == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white, size: 30)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: controller.groupNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nama Grup...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(CreateGroupController controller) {
    // ... (kode ini tetap sama)
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(child: Text(controller.errorMessage!));
    }
    return ListView.builder(
      itemCount: controller.filteredFollowers.length,
      itemBuilder: (context, index) {
        final user = controller.filteredFollowers[index];
        final isSelected = controller.selectedUsers.contains(user);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profilePictureUrl != null
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child: user.profilePictureUrl == null
                ? Text(user.username.substring(0, 1).toUpperCase())
                : null,
          ),
          title: Text(user.fullName ?? user.username),
          subtitle: Text('@${user.username}'),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (_) => controller.toggleUserSelection(user),
            shape: const CircleBorder(),
            activeColor: Theme.of(context).primaryColor,
          ),
          onTap: () => controller.toggleUserSelection(user),
        );
      },
    );
  }
}
