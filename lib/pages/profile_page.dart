// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/models/post_model.dart';
import '../components/bottom_navigation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'post_detail.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- Menggunakan Tipe Data yang Benar ---
  User? _user;
  List<Post> _userPosts = [];
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- Logika Pengambilan Data yang Sudah Benar ---
  Future<void> _loadAllData() async {
    setStateIfMounted(() => _isLoading = true);
    try {
      final user = await ProfileService().getProfile();
      if (!mounted) return;

      setStateIfMounted(() => _user = user);

      final userId = user.id;
      if (userId == null) {
        throw Exception('User ID tidak valid.');
      }

      final userPostsResult = await _fetchUserPosts(userId);
      await _fetchFollowData(userId);

      if (mounted) {
        setStateIfMounted(() {
          _userPosts = userPostsResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setStateIfMounted(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  Future<List<Post>> _fetchUserPosts(int userId) async {
    final allPosts = await PostService().fetchAllPosts();
    return allPosts.where((post) => post.user.id == userId).toList();
  }

  Future<void> _fetchFollowData(int userId) async {
    try {
      final followersData = await FollowService().getFollowers(userId);
      final followingData = await FollowService().getFollowing(userId);
      setStateIfMounted(() {
        _followers = followersData;
        _following = followingData;
      });
    } catch (e) {
      print("Error loading follow data: $e");
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(initialProfile: _user!)),
    );
    if (result == true) {
      _loadAllData();
    }
  }

  void _navigateToFollowersFollowing(int initialTab) {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: _user!.id!,
          initialTab: initialTab,
          followers: _followers,
          following: _following,
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == 4) return;
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
  }

  // --- Widget Build Utama ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar:
          CustomBottomNavigation(selectedIndex: 4, onTap: _onBottomNavTapped),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Gagal memuat data: $_error"),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadAllData, child: const Text("Coba Lagi"))
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: CustomScrollView(
        slivers: [
          _buildHeader(), // Menggunakan header versi detail
          SliverToBoxAdapter(child: _buildProfileSection()),
          _buildPostGridSliver(),
        ],
      ),
    );
  }

  // --- KODE UI DETAIL DARI FILE ASLI ANDA DIKEMBALIKAN & DIPERBAIKI ---

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: 200,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      centerTitle: true,
      title: Text(
        _user?.username ?? 'Profil',
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.black),
          onSelected: (value) async {
            if (value == 'logout') {
              await AuthService().logout();
              if (mounted)
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              // Menggunakan profile picture sebagai background header
              image: NetworkImage(_user?.profilePictureUrl ??
                  'https://i.pinimg.com/1200x/8c/56/c4/8c56c483afc07fbbc8d1c937c53c26b1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                _user?.username ?? 'Nama tidak tersedia',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(_user?.profilePictureUrl ??
                            'https://via.placeholder.com/150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _navigateToEditProfile,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(_userPosts.length.toString(), 'postingan'),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(0),
                      child: _buildStatItem(
                          _followers.length.toString(), 'pengikut'),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(1),
                      child: _buildStatItem(
                          _following.length.toString(), 'mengikuti'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.fullName ?? 'Nama tidak tersedia',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.bio ?? 'Tidak ada bio',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Edit profile',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Bagikan Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPostGridSliver() {
    if (_userPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(50.0),
            child: Text('Belum ada postingan'),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final Post post = _userPosts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetail(postId: post.id),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.mediaUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
          childCount: _userPosts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }
}
