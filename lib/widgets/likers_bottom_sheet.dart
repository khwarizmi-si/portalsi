// lib/widgets/likers_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/models/liker_model.dart';
import 'package:portal_si/services/follow_service.dart';
import 'package:portal_si/services/post_service.dart';
import 'package:portal_si/utils/navigation_helper.dart';

import '../models/user_model.dart';

class LikersBottomSheet extends StatefulWidget {
  final int postId;
  const LikersBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<LikersBottomSheet> createState() => _LikersBottomSheetState();
}

class _LikersBottomSheetState extends State<LikersBottomSheet> {
  late Future<List<Liker>> _likersFuture;
  final TextEditingController _searchController = TextEditingController();
  List<Liker> _allLikers = [];
  List<Liker> _filteredLikers = [];

  @override
  void initState() {
    super.initState();
    _likersFuture = PostService().getPostLikers(widget.postId);
    _likersFuture.then((value) {
      setState(() {
        _allLikers = value;
        _filteredLikers = value;
      });
    });
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLikers = _allLikers.where((liker) {
        return liker.username.toLowerCase().contains(query) ||
            (liker.fullName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Header
              const Text('Likes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Daftar Likers
              Expanded(
                child: FutureBuilder<List<Liker>>(
                  future: _likersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Tidak ada yang menyukai post ini.', style: TextStyle(color: Colors.white70)));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredLikers.length,
                      itemBuilder: (context, index) {
                        // --- TAMBAHKAN KEY DI SINI ---
                        return _LikerTile(
                          key: ValueKey(_filteredLikers[index].userId), // Use userId as a unique key
                          liker: _filteredLikers[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LikerTile extends StatefulWidget {
  final Liker liker;
  const _LikerTile({Key? key, required this.liker}) : super(key: key);

  @override
  State<_LikerTile> createState() => _LikerTileState();
}

class _LikerTileState extends State<_LikerTile> {
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.liker.isFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final followService = FollowService();
    bool success;
    if(_isFollowing) {
      success = await followService.unfollowUser(widget.liker.userId);
    } else {
      success = await followService.followUser(widget.liker.userId);
    }

    if(success) {
      setState(() {
        _isFollowing = !_isFollowing;
        widget.liker.isFollowing = _isFollowing; // Update model
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircularAvatarFetcher(radius: 22, userId: widget.liker.userId),
      title: Text(widget.liker.username, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      subtitle: Text(widget.liker.fullName ?? '', style: TextStyle(color: Colors.grey[400])),
      trailing: widget.liker.isCurrentUser
          ? null
          : SizedBox(
        width: 100,
        height: 35,
        // =================================================================
        // --- PERUBAHAN UTAMA ADA DI SINI ---
        // =================================================================
        child: ElevatedButton(
          onPressed: _isLoading ? null : _toggleFollow,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // Hapus padding internal
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            // Atur warna berdasarkan status, buat transparan untuk gradien
            backgroundColor: _isFollowing ? Colors.grey[700] : Colors.transparent,
            // Hapus bayangan saat gradien aktif
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          child: Ink(
            decoration: BoxDecoration(
              // Terapkan gradien hanya saat statusnya bukan 'Following'
              gradient: _isFollowing ? null : LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade800],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);

        // 1. Buat objek User baru dari data yang ada di 'widget.liker'
        final userToNavigate = User(
          id: widget.liker.userId, // Asumsi properti ini ada di model Liker
          username: widget.liker.username,
          // Tambahkan properti lain dari 'liker' jika ada dan diperlukan
          // Contoh:
          // fullName: widget.liker.fullName,
          // profilePictureUrl: widget.liker.profilePictureUrl,
          // isVerified: widget.liker.isVerified,
        );

        // 2. Kirim objek User yang baru dibuat ke fungsi navigasi
        NavigationHelper.navigateToProfile(
          context,
          userToNavigate,
        );
      },
    );
  }
}