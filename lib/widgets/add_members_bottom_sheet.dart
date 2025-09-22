// lib/widgets/add_members_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:portal_si/models/user_model.dart';
import 'package:portal_si/services/follow_service.dart';
import 'package:portal_si/services/group_service.dart';

import '../utils/secure_storage.dart';

class AddMembersBottomSheet extends StatefulWidget {
  final int groupId;
  const AddMembersBottomSheet({super.key, required this.groupId});

  @override
  State<AddMembersBottomSheet> createState() => _AddMembersBottomSheetState();
}

class _AddMembersBottomSheetState extends State<AddMembersBottomSheet> {
  final FollowService _followService = FollowService();
  final GroupService _groupService = GroupService();

  List<User> _mutuals = [];
  final Set<User> _selectedUsers = {};
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    try {
      // Ambil ID pengguna yang sedang login
      final currentUserId = await SecureStorage.getUserId();
      if (currentUserId == null) throw Exception("User ID tidak ditemukan");

      // Panggil fungsi service yang benar dengan ID pengguna
      final users = await _followService.getFollowingList(currentUserId);

      if (mounted) {
        setState(() {
          _mutuals = users; // Simpan ke state _mutuals (atau ganti namanya jadi _following)
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching following list: $e");
    }
  }

  void _toggleSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _isAdding = true);
    int successCount = 0;

    // Panggil API untuk setiap user yang dipilih
    for (final user in _selectedUsers) {
      final success = await _groupService.addMemberByIdentifier(
        groupId: widget.groupId,
        identifier: user.username, // Gunakan username sebagai identifier
      );
      if (success) successCount++;
    }

    if (mounted) {
      setState(() => _isAdding = false);
      Navigator.pop(context, true); // Kirim 'true' untuk menandakan ada perubahan

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount anggota berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Text('Tambahkan Anggota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _mutuals.length,
              itemBuilder: (context, index) {
                final user = _mutuals[index];
                final isSelected = _selectedUsers.contains(user);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.profilePictureUrl ?? ''),
                  ),
                  title: Text(user.fullName ?? user.username),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(user),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  onTap: () => _toggleSelection(user),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selectedUsers.isEmpty || _isAdding ? null : _addSelectedMembers,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isAdding
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Tambahkan ${_selectedUsers.length} Anggota'),
          ),
        ],
      ),
    );
  }
}