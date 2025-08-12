import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/models/post_model.dart';
import '../components/bottom_navigation.dart';
import '../utils/secure_storage.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import 'dashboard_page.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart'; // Import halaman baru
import 'package:portal_si/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;
  Map<String, dynamic>? _user;
  bool _isLoadingUser = true;
  List<dynamic> _userPosts = [];
  bool _isLoadingPosts = true;
  final FollowService _followService = FollowService();
  final ProfileService _profileService = ProfileService();

  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isLoadingFollowData = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> fetchFollowData() async {
    if (!mounted) return;

    setState(() => isLoadingFollowData = true);

    try {
      final userIdStr = await SecureStorage.getToken();
      userId = int.tryParse(userIdStr ?? '');

      if (userId == null) {
        // Coba ambil dari user data yang sudah dimuat
        if (_user != null) {
          userId = _user!['user']['user_id'];
        } else {
          throw Exception('User ID tidak valid');
        }
      }

      final fetchedFollowers = await _followService.getFollowers(userId!);
      final fetchedFollowing = await _followService.getFollowing(userId!);

      if (mounted) {
        setState(() {
          followers = fetchedFollowers;
          following = fetchedFollowing;
          isLoadingFollowData = false;
        });
      }
    } catch (e) {
      print('Error ambil followers/following: $e');
      if (mounted) {
        setState(() => isLoadingFollowData = false);
        // Tampilkan snackbar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Gagal memuat data followers/following: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUser() async {
    final userData = await AuthService().getUser();
    if (userData == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    setState(() {
      _user = userData;
      _isLoadingUser = false;
    });

    // Setelah user data dimuat, ambil data follow dan posts
    await Future.wait([
      _fetchUserPosts(),
      fetchFollowData(),
    ]);
  }

  Future<void> _fetchUserPosts() async {
    if (_user == null) return;

    try {
      // 1. fetchAllPosts() sudah mengembalikan List<Post>
      final allPosts = await PostService().fetchAllPosts();
      final userId = _user!['user']['user_id'].toString();

      // 2. Filter dengan mengakses properti objek Post secara langsung
      final userPosts = allPosts.where((post) {
        // 'post' adalah objek Post, akses propertinya langsung
        // Asumsi: objek Post memiliki properti 'user' yang merupakan objek User
        // dan objek User memiliki properti 'id'.
        return post.user.id.toString() == userId;
      }).toList();

      if (mounted) {
        setState(() {
          _userPosts = userPosts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
        print('Error fetching user posts: $e');
      }
    }
  }

  // Navigasi ke EditProfilePage
  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;

    // Convert user data ke ProfileModel
    final currentProfile = ProfileModel.fromAuthData(_user!);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(initialProfile: currentProfile),
      ),
    );

    // Refresh profile data jika edit berhasil
    if (result == true) {
      await _loadUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Navigasi ke halaman followers/following
  void _navigateToFollowersFollowing(int initialTab) {
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: userId!,
          initialTab: initialTab,
          followers: followers,
          following: following,
        ),
      ),
    ).then((value) {
      // Refresh data setelah kembali dari halaman followers/following
      if (value == true) {
        fetchFollowData();
      }
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    if (index == 1) Navigator.pushReplacementNamed(context, '/feed');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // AppBar sebagai sliver
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              floating: true,
              snap: true,
              pinned: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _isLoadingUser
                    ? 'Memuat...'
                    : _user?['user']?['username'] ?? 'Nama tidak tersedia',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                  letterSpacing: 0.2,
                ),
              ),
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await AuthService().logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),

            // Konten utama sebagai sliver
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  // Profile Info
                  _buildProfileSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Grid Posts sebagai sliver
            _buildPostGridSliver(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://i.pinimg.com/1200x/8c/56/c4/8c56c483afc07fbbc8d1c937c53c26b1.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Text(
              _isLoadingUser
                  ? 'Memuat...'
                  : _user?['user']?['username'] ?? 'Nama tidak tersedia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
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
              // Profile picture with enhanced styling
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
                        image: NetworkImage(
                          _user?['user']?['profile_picture_url'] ??
                              'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
                        ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),

          // Bio dan Statistik with improved spacing
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio section with better typography
                Text(
                  _isLoadingUser
                      ? 'Memuat...'
                      : _user?['user']?['full_name'] ?? 'Nama tidak tersedia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[900],
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    _isLoadingUser
                        ? 'Memuat...'
                        : (_user?['user']?['bio'] ?? 'Tidak ada bio'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced statistics section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(_userPosts.length.toString(), 'postingan'),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      GestureDetector(
                        onTap: () =>
                            _navigateToFollowersFollowing(0), // Tab followers
                        child: _buildStatItem(
                            isLoadingFollowData
                                ? '...'
                                : followers.length.toString(),
                            'pengikut'),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      GestureDetector(
                        onTap: () =>
                            _navigateToFollowersFollowing(1), // Tab following
                        child: _buildStatItem(
                            isLoadingFollowData
                                ? '...'
                                : following.length.toString(),
                            'mengikuti'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Enhanced Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Implementasi share profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fitur bagikan profile akan segera hadir!',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Bagikan Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPostGridSliver() {
    if (_isLoadingPosts) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada postingan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Postingan yang Anda bagikan akan muncul di sini',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Tentukan tipe data post agar lebih aman
          final Post post = _userPosts[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(80, 0, 0, 0),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // PERBAIKAN: Gunakan post.mediaUrl
                  Image.network(
                    post.mediaUrl ??
                        'https://via.placeholder.com/300x300?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PERBAIKAN: Gunakan post.caption
                        if (post.caption != null && post.caption!.isNotEmpty)
                          Text(
                            post.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // PERBAIKAN: Gunakan post.location
                        if (post.location != null && post.location!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    post.location!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // PERBAIKAN: Gunakan post.isVideo (asumsi tipe datanya bool)
                        if (post.isVideo)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _userPosts.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }
}
