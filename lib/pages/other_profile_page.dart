// lib/pages/other_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../models/post_model.dart';
import '../services/user_service.dart'; // Menggunakan nama service yang benar
import '../services/post_service.dart';
import '../services/follow_service.dart';
import 'followers_following_page.dart';

// Asumsi ProfileModel ada di file user_service.dart (atau profile_service.dart)
// Jika sudah dipisah, import file modelnya di sini.

class OtherProfilePage extends StatefulWidget {
  final String username;

  const OtherProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with TickerProviderStateMixin {
  ProfileModel? _profileData;
  List<Post> _userPosts = [];
  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowActionLoading = false;
  String? _error;

  // Animasi dari kode asli Anda
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      final profile = await ProfileService().getOtherProfile(widget.username);
      final followStatus =
          await FollowService().getFollowStatus(widget.username);
      final isCurrentlyFollowing = followStatus['isFollowing'] ?? false;

      final futurePosts = _fetchUserPosts(profile.username);
      final futureFollowData = _fetchFollowData(profile.id);

      final userPostsResult = await futurePosts;
      await futureFollowData;

      if (mounted) {
        setState(() {
          _profileData = profile;
          _isFollowing = isCurrentlyFollowing;
          _userPosts = userPostsResult;
          _isLoading = false;
        });
        _animationController.forward(
            from: 0.0); // Jalankan animasi setelah data dimuat
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

  Future<List<Post>> _fetchUserPosts(String targetUsername) async {
    final allPosts = await PostService().fetchAllPosts();
    return allPosts
        .where((post) => post.user.username == targetUsername)
        .toList();
  }

  Future<void> _fetchFollowData(int userId) async {
    try {
      final fetchedFollowers = await FollowService().getFollowers(userId);
      final fetchedFollowing = await FollowService().getFollowing(userId);
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
      if (_isFollowing) {
        await FollowService().unfollowUser(username);
        if (mounted) setState(() => _isFollowing = false);
      } else {
        await FollowService().followUser(username);
        if (mounted) setState(() => _isFollowing = true);
      }
      await _fetchFollowData(_profileData!.id);
    } finally {
      if (mounted) setState(() => _isFollowActionLoading = false);
    }
  }

  void _navigateToFollowersFollowing(int initialTab) {
    if (_profileData == null) return;
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
    ).then((_) => _fetchFollowData(_profileData!.id));
  }

  // --- KODE UI YANG DIKEMBALIKAN KE VERSI ASLI ANDA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar:
          CustomBottomNavigation(selectedIndex: 4, onTap: (_) {}),
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
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _profileData?.username ?? 'Profil',
        style: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onPressed: () {/* _showMoreOptions */},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'cover_${_profileData?.username ?? ''}',
          child: Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                    'https://i.pinimg.com/1200x/fb/23/03/fb2303e0fdae024825b9d15a3389e2da.jpg'),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
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
            children: [
              Hero(
                tag: 'profile_${_profileData?.username ?? ''}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileData!.profilePictureUrl.isNotEmpty
                        ? NetworkImage(_profileData!.profilePictureUrl)
                        : null,
                    child: _profileData!.profilePictureUrl.isEmpty
                        ? Icon(Icons.person, size: 45, color: Colors.grey[600])
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                        _userPosts.length.toString(), 'Postingan', null),
                    _buildStatItem(_followers.length.toString(), 'Pengikut',
                        () => _navigateToFollowersFollowing(0)),
                    _buildStatItem(_following.length.toString(), 'Mengikuti',
                        () => _navigateToFollowersFollowing(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _profileData!.fullName.isNotEmpty
                ? _profileData!.fullName
                : _profileData!.username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (_profileData!.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _profileData!.bio,
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
                    child: CircularProgressIndicator(strokeWidth: 2))
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
    if (_userPosts.isEmpty) {
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final Post post = _userPosts[index]; // <-- Logika sudah benar
          return GestureDetector(
            onTap: () => _showImageDetail(
                post, index), // <-- FUNGSI INI DITAMBAHKAN KEMBALI
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag:
                          'post_${post.id}_$index', // Gunakan ID post agar unik
                      child: Image.network(
                        post.mediaUrl ?? '', // <-- Logika sudah benar
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Jika ingin ada gradient atau info tambahan, tambahkan di sini
                  ],
                ),
              ),
            ),
          );
        }, childCount: _userPosts.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }

  // --- FUNGSI UNTUK MELIHAT DETAIL GAMBAR DARI KODE ASLI ANDA ---
  void _showImageDetail(Post post, int index) {
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
                style: const TextStyle(
                    color: Colors.white)), // <-- Logika sudah benar
          ),
          body: Center(
            child: Hero(
              tag: 'post_${post.id}_$index', // Tag harus sama persis
              child: InteractiveViewer(
                child: Image.network(
                  post.mediaUrl ?? '', // <-- Logika sudah benar
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
