// lib/widgets/add_members_bottom_sheet.dart (VERSI BERSIH)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:portal_si/services/follow_service.dart';
import 'package:portal_si/services/group_service.dart';
// Asumsi Anda memiliki model User
import 'package:portal_si/models/user_model.dart';

class AddMembersBottomSheet extends StatefulWidget {
  final int groupId;

  const AddMembersBottomSheet({super.key, required this.groupId});

  @override
  State<AddMembersBottomSheet> createState() => _AddMembersBottomSheetState();
}

class _AddMembersBottomSheetState extends State<AddMembersBottomSheet> {
  final FollowService _followService = FollowService();
  final GroupService _groupService = GroupService();

  // STATE UNTUK PENCARIAN
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = []; // Gunakan model User untuk type safety
  bool _isSearching = false;
  String _searchQuery = '';

  // STATE UNTUK DAFTAR FOLLOWING
  late Future<List<User>> _followingFuture; // Gunakan model User

  // STATE UNTUK KELOLA TOMBOL 'TAMBAH'
  final Set<int> _addedUserIds = <int>{};
  final Set<int> _addingInProgressUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    // Panggil dengan parameter yang benar.
    // Asumsi '0' akan diganti dengan ID user yang sedang login.
    _followingFuture = _followService.getFollowing(0, forceRefresh: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    // Asumsi service mengembalikan List<User>
    final results = await _followService.searchUsers(_searchQuery);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // Fungsi untuk menambahkan satu anggota
  Future<void> _addMember(User user) async {
    // Gunakan user.id untuk mengelola state tombol
    final int? userId = user.id;
    if (userId == null || _addingInProgressUserIds.contains(userId)) return;

    setState(() => _addingInProgressUserIds.add(userId));

    try {
      // --- PERUBAHAN UTAMA: KIRIM user.username SEBAGAI IDENTIFIER ---
      final success = await _groupService.addMemberByIdentifier(
          groupId: widget.groupId,
          identifier: user.username // Mengirim username (String)
      );

      if (success && mounted) {
        setState(() => _addedUserIds.add(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anggota berhasil ditambahkan."), backgroundColor: Colors.green),
        );
      } else if (!success) {
        throw Exception("Gagal menambahkan anggota dari server.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingInProgressUserIds.remove(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisplayingSearchResults = _searchQuery.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tambah Anggota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama atau username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Konten List
          Expanded(
            child: isDisplayingSearchResults
                ? _buildSearchResults()
                : _buildFollowingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList() {
    return FutureBuilder<List<User>>(
      future: _followingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Gagal memuat daftar following: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Anda belum mengikuti siapa pun."));
        }

        final following = snapshot.data!;
        return _buildUserListView(
          users: following,
          listTitle: "Yang Anda Ikuti",
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text("Tidak ada hasil ditemukan."));
    }

    return _buildUserListView(
      users: _searchResults,
      listTitle: "Hasil Pencarian",
    );
  }

  Widget _buildUserListView({required List<User> users, required String listTitle}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          listTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...users.map((user) => _buildUserTile(user)).toList(),
      ],
    );
  }

  Widget _buildUserTile(User user) {
    // Pastikan user.id tidak null
    final int userId = user.id ?? -1;
    if (userId == -1) return const SizedBox.shrink(); // Jangan render jika ID tidak valid

    final bool isAdded = _addedUserIds.contains(userId);
    final bool isAdding = _addingInProgressUserIds.contains(userId);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
            ? NetworkImage(user.profilePictureUrl!)
            : null,
        child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.fullName ?? user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('@${user.username}'),
      trailing: ElevatedButton(
        onPressed: isAdded || isAdding ? null : () => _addMember(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAdded ? Colors.grey : Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: isAdding
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(isAdded ? 'Ditambahkan' : 'Tambah'),
      ),
    );
  }
}