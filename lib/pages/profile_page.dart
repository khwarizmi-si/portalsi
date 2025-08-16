// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. IMPORT PROVIDER
import 'package:portal_si/controllers/home_controller.dart'; // <-- 2. IMPORT CONTROLLER
import 'package:portal_si/models/user_model.dart';
import '../components/bottom_navigation.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'post_detail.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // [OPTIMASI] State lokal hanya untuk menampung daftar lengkap saat dibutuhkan
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  // [DIHAPUS] _user, _isLoading, _error, dan _loadAllData tidak lagi diperlukan
  // karena semua data diambil dari HomeController.

  // [OPTIMASI] Fungsi ini hanya dipanggil saat tombol pengikut/mengikuti ditekan
  Future<void> _fetchFollowData(int userId) async {
    try {
      final followersData = await FollowService().getFollowers(userId);
      final followingData = await FollowService().getFollowing(userId);
      if (mounted) {
        setState(() {
          _followers = followersData;
          _following = followingData;
        });
      }
    } catch (e) {
      print("Error loading follow data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal memuat daftar pengikut.")));
      }
    }
  }

  // [DIUBAH] Menerima 'user' sebagai parameter dari Consumer
  Future<void> _navigateToEditProfile(User user) async {
    final homeController = Provider.of<HomeController>(context, listen: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(initialProfile: user)),
    );
    // Jika ada perubahan, refresh data di HomeController
    if (result == true) {
      homeController.fetchPosts(isRefresh: true);
    }
  }

  // [DIUBAH] Menerima 'user' sebagai parameter
  void _navigateToFollowersFollowing(User user, int initialTab) {
    _fetchFollowData(user.id).then((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersFollowingPage(
              userId: user.id,
              initialTab: initialTab,
              followers: _followers,
              following: _following,
            ),
          ),
        );
      }
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 4) return;
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // [DIUBAH] Widget utama sekarang dibungkus Consumer<HomeController>
      body: Consumer<HomeController>(
        builder: (context, controller, child) {
          // Tampilkan loading indicator dari controller
          if (controller.isLoading && controller.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tampilkan error dari controller
          if (controller.errorMessage != null &&
              controller.currentUser == null) {
            return Center(child: Text(controller.errorMessage!));
          }

          // Ambil data user dari controller
          final user = controller.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Gagal memuat data pengguna."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchPosts(isRefresh: true),
                      child: const Text("Coba Lagi"),
                    )
                  ]),
            );
          }

          // Jika data user ada, bangun UI-nya
          return _buildProfileView(user);
        },
      ),
      bottomNavigationBar:
          CustomBottomNavigation(selectedIndex: 4, onTap: _onBottomNavTapped),
    );
  }

  // [BARU] Widget untuk membangun view profil utama
  Widget _buildProfileView(User user) {
    return RefreshIndicator(
      onRefresh: () => Provider.of<HomeController>(context, listen: false)
          .fetchPosts(isRefresh: true),
      child: CustomScrollView(
        slivers: [
          _buildHeader(user),
          SliverToBoxAdapter(child: _buildProfileSection(user)),
          _buildPostGridSliver(user),
        ],
      ),
    );
  }

  Widget _buildHeader(User user) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: 200,
      pinned: true,
      elevation: 1,
      centerTitle: true,
      title: Text(
        user.username,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.black),
          onSelected: (value) async {
            if (value == 'logout') {
              await AuthService().logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          user.profilePictureUrl ?? 'https://via.placeholder.com/400',
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.3),
          colorBlendMode: BlendMode.darken,
        ),
      ),
    );
  }

  Widget _buildProfileSection(User user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      transform:
          Matrix4.translationValues(0.0, -20.0, 0.0), // Efek agar sedikit naik
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.profilePictureUrl != null &&
                              user.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _navigateToEditProfile(user),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(user.postsCount.toString(), 'Postingan'),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(user, 0),
                      child: _buildStatItem(
                          user.followersCount.toString(), 'Pengikut'),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(user, 1),
                      child: _buildStatItem(
                          user.followingCount.toString(), 'Mengikuti'),
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
                  user.fullName ?? 'Nama tidak tersedia',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio ?? 'Tidak ada bio',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToEditProfile(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Edit Profil',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Bagikan Profil'),
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

  Widget _buildPostGridSliver(User user) {
    final posts = user.recentPosts;

    if (posts.isEmpty) {
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
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostDetail(postId: post.postId)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: Colors.grey[200]);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey));
                  },
                ),
              ),
            );
          },
          childCount: posts.length,
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
