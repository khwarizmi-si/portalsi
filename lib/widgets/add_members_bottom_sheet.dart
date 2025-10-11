// lib/widgets/add_members_bottom_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:portal_si/services/group_service.dart';
import 'package:portal_si/models/user_model.dart';

class AddMembersBottomSheet extends StatefulWidget {
  final int groupId;

  const AddMembersBottomSheet({super.key, required this.groupId});

  @override
  State<AddMembersBottomSheet> createState() => _AddMembersBottomSheetState();
}

class _AddMembersBottomSheetState extends State<AddMembersBottomSheet> {
  final GroupService _groupService = GroupService();

  // STATE UNTUK PENCARIAN
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // STATE UNTUK DAFTAR MUTUALS DENGAN PAGINATION
  final List<User> _mutuals = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isFirstLoad = true;
  bool _isLoadingNextPage = false;

  // STATE UNTUK KELOLA TOMBOL 'TAMBAH'
  final Set<int> _addedUserIds = <int>{};
  final Set<int> _addingInProgressUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    _fetchInitialMutuals();
    _searchController.addListener(_onSearchChanged);

    _scrollController.addListener(() {
      // Trigger fetch more data when user scrolls to the end of the list
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          _hasNextPage &&
          !_isLoadingNextPage) {
        _fetchMoreMutuals();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialMutuals() async {
    setState(() {
      _isFirstLoad = true;
    });
    try {
      final response = await _groupService.getMutuals(page: 1);
      final List<dynamic> userListJson = response['data'] as List<dynamic>;
      final newUsers = userListJson.map((json) => User.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _mutuals.clear();
          _mutuals.addAll(newUsers);
          _currentPage = 1;
          _hasNextPage = response['next_page_url'] != null;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat daftar teman: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchMoreMutuals() async {
    setState(() {
      _isLoadingNextPage = true;
    });
    try {
      final response = await _groupService.getMutuals(page: _currentPage + 1);
      final List<dynamic> userListJson = response['data'] as List<dynamic>;
      final newUsers = userListJson.map((json) => User.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _mutuals.addAll(newUsers);
          _currentPage++;
          _hasNextPage = response['next_page_url'] != null;
          _isLoadingNextPage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNextPage = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_searchQuery == query) return;

    setState(() {
      _searchQuery = query;
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
    try {
      final response = await _groupService.searchUsers(query: _searchQuery, page: 1);
      final List<dynamic> userListJson = response['data'] as List<dynamic>;
      final results = userListJson.map((json) => User.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal melakukan pencarian: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addMember(User user) async {
    final int? userId = user.id;
    if (userId == null || _addingInProgressUserIds.contains(userId) || _addedUserIds.contains(userId)) return;

    setState(() => _addingInProgressUserIds.add(userId));

    try {
      final success = await _groupService.addMemberByIdentifier(
        groupId: widget.groupId,
        identifier: user.username,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tambah Anggota',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
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
          Expanded(
            child: isDisplayingSearchResults
                ? _buildSearchResults()
                : _buildMutualsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualsList() {
    if (_isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mutuals.isEmpty) {
      return const Center(child: Text("Anda tidak memiliki teman mutual."));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _mutuals.length + (_hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _mutuals.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = _mutuals[index];
        return _buildUserTile(user);
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_searchResults[index]);
      },
    );
  }

  Widget _buildUserTile(User user) {
    final int userId = user.id ?? -1;
    if (userId == -1) return const SizedBox.shrink();

    final bool isAdded = _addedUserIds.contains(userId);
    final bool isAdding = _addingInProgressUserIds.contains(userId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        radius: 24,
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