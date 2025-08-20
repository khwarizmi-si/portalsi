// lib/pages/other_profile_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/models/user_model.dart';
import '../components/bottom_navigation.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import 'followers_following_page.dart';

class OtherProfilePage extends StatefulWidget {
  final String username;

  const OtherProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with TickerProviderStateMixin {
  // [DIUBAH] Menggunakan User model, bukan ProfileModel lagi
  User? _profileData;
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowActionLoading = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // [LEBIH EFISIEN] Cukup satu panggilan API untuk mendapatkan semua data utama
      final profile = await ProfileService().getOtherProfile(widget.username);
      final followStatus =
      await FollowService().getFollowStatus(widget.username);

      if (mounted) {
        setState(() {
          _profileData = profile;
          _isFollowing = followStatus['isFollowing'] ?? false;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat profil: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi ini dipanggil hanya saat diperlukan untuk melihat daftar lengkap
  Future<void> _fetchFollowData() async {
    if (_profileData == null) return;
    try {
      final fetchedFollowers =
      await FollowService().getFollowers(_profileData!.id);
      final fetchedFollowing =
      await FollowService().getFollowing(_profileData!.id);
      if (mounted) {
        setState(() {
          _followers = fetchedFollowers;
          _following = fetchedFollowing;
        });
      }
    } catch (e) {
      print("Gagal memuat data follow: $e");
    }
  }

  Future<void> _handleFollowAction() async {
    if (_isFollowActionLoading || _profileData == null) return;
    setState(() => _isFollowActionLoading = true);

    try {
      final username = _profileData!.username;
      final originalFollowersCount = _profileData!.followersCount;

      if (_isFollowing) {
        // Optimistic update for unfollow
        setState(() {
          _isFollowing = false;
          _profileData = _profileData!
              .copyWith(followersCount: originalFollowersCount - 1);
        });
        await FollowService().unfollowUser(username);
      } else {
        // Optimistic update for follow
        setState(() {
          _isFollowing = true;
          _profileData = _profileData!
              .copyWith(followersCount: originalFollowersCount + 1);
        });
        await FollowService().followUser(username);
      }
    } catch (e) {
      // Rollback on error
      await _loadAllData(); // Reload all data to ensure consistency
    } finally {
      if (mounted) setState(() => _isFollowActionLoading = false);
    }
  }

  void _navigateToFollowersFollowing(int initialTab) {
    if (_profileData == null) return;
    _fetchFollowData().then((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersFollowingPage(
              userId: _profileData!.id,
              initialTab: initialTab,
              followers: _followers,
              following: _following,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar:
      CustomBottomNavigation(selectedIndex: 0, onTap: (_) {}),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(
                onPressed: _loadAllData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileSection()),
            _buildPostGridSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _profileData?.username ?? 'Profil',
        style: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'cover_${_profileData?.username ?? ''}',
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_profileData?.profilePictureUrl ??
                    'https://via.placeholder.com/400'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_profileData == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: 'profile_${_profileData!.username}',
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileData!.profilePictureUrl != null &&
                      _profileData!.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(_profileData!.profilePictureUrl!)
                      : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                        _profileData!.postsCount.toString(), 'Postingan', null),
                    _buildStatItem(_profileData!.followersCount.toString(),
                        'Pengikut', () => _navigateToFollowersFollowing(0)),
                    _buildStatItem(_profileData!.followingCount.toString(),
                        'Mengikuti', () => _navigateToFollowersFollowing(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _profileData!.fullName ?? _profileData!.username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (_profileData!.bio != null && _profileData!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _profileData!.bio!,
              style:
              TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
            ),
          ],
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isFollowActionLoading ? null : _handleFollowAction,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              _isFollowing ? Colors.grey[200] : Colors.blueAccent,
              foregroundColor: _isFollowing ? Colors.black : Colors.white,
              elevation: _isFollowing ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: _isFollowing
                    ? BorderSide(color: Colors.grey[300]!)
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isFollowActionLoading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Text(_isFollowing ? 'Mengikuti' : 'Ikuti',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {/* Logika Pesan */},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Pesan',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPostGridSliver() {
    if (_profileData == null || _profileData!.recentPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50.0),
            child: Text('Belum ada postingan.'),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final post = _profileData!.recentPosts[index];
            return GestureDetector(
              onTap: () => _showImageDetail(post, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'post_${post.postId}_$index',
                  child: Image.network(post.mediaUrl, fit: BoxFit.cover),
                ),
              ),
            );
          },
          childCount: _profileData!.recentPosts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }

  void _showImageDetail(SimplePost post, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(post.caption ?? '',
                style: const TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Hero(
              tag: 'post_${post.postId}_$index', // Tag harus sama persis
              child: InteractiveViewer(
                child: Image.network(post.mediaUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tambahan: Implementasi copyWith pada User model jika belum ada.
// Buka file user_model.dart dan tambahkan method ini di dalam class User
extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? username,
    int? followersCount,
    // ...tambahkan field lain yang ingin di-update
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      followersCount: followersCount ?? this.followersCount,
      // Salin nilai field lain dari objek `this`
      email: this.email,
      fullName: this.fullName,
      bio: this.bio,
      profilePictureUrl: this.profilePictureUrl,
      isVerified: this.isVerified,
      isPrivate: this.isPrivate,
      followingCount: this.followingCount,
      postsCount: this.postsCount,
      recentPosts: this.recentPosts,
      role: this.role,
    );
  }
}