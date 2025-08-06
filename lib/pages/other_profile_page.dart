import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart'; // ✅ Add FollowService import

class OtherProfilePage extends StatefulWidget {
  final String? username; // ✅ Changed from int? userId to String? username

  const OtherProfilePage({Key? key, this.username}) : super(key: key);

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 4;
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isLoadingPosts = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService(); // ✅ Add FollowService
  ProfileModel? _profileData;

  List<dynamic> _userPosts = [];

  // ✅ Add follow counts
  int _followersCount = 0;
  int _followingCount = 0;

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
    _animationController.forward();

    _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _profileService.dispose();
    // _followService doesn't need disposal as it doesn't have persistent connections
    super.dispose();
  }

  // ✅ UPDATED: Load profile data using username and check follow status
  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoadingProfile = true;
        _error = null;
      });

      final username = widget.username;
      if (username == null || username.isEmpty) {
        throw Exception('Username is required');
      }

      // ✅ Load profile data
      final profile = await _profileService.getOtherProfile(username);

      // ✅ Check follow status
      final followStatus = await _followService.getFollowStatus(username);
      final isCurrentlyFollowing = followStatus['isFollowing'] ?? false;

      // ✅ Get follow counts
      final followCounts = await _followService.getFollowCounts(username);

      setState(() {
        _profileData = profile;
        _isFollowing = isCurrentlyFollowing;
        _followersCount = followCounts['followers'] ?? 0;
        _followingCount = followCounts['following'] ?? 0;
        _isLoadingProfile = false;
      });

      // Load posts after profile is loaded
      _fetchUserPosts();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingProfile = false;
        _isLoadingPosts = false;
      });
    }
  }

  // ✅ UPDATED: Fetch user posts by username instead of userId
  Future<void> _fetchUserPosts() async {
    if (widget.username == null || _profileData == null) return;

    try {
      setState(() {
        _isLoadingPosts = true;
      });

      final allPosts = await PostService().fetchAllPosts();
      final targetUsername =
          _profileData!.username; // Use username from profile data

      // ✅ Filter posts by username instead of user_id
      final userPosts = allPosts.where((post) {
        final postMap = post as Map<String, dynamic>;
        // Assuming the post has a 'username' field, adjust if different
        return postMap['username']?.toString() == targetUsername ||
            postMap['user']?['username']?.toString() == targetUsername;
      }).toList();

      if (mounted) {
        setState(() {
          _userPosts = userPosts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
        print('Error fetching user posts: $e');
      }
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/feed');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // ✅ UPDATED: Real follow/unfollow implementation
  Future<void> _handleFollowAction() async {
    if (_isLoading || _profileData == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final username = _profileData!.username;
      bool success = false;

      if (_isFollowing) {
        // Unfollow user
        success = await _followService.unfollowUser(username);
        if (success) {
          setState(() {
            _isFollowing = false;
            _followersCount = _followersCount > 0 ? _followersCount - 1 : 0;
          });
        }
      } else {
        // Follow user
        success = await _followService.followUser(username);
        if (success) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
      }

      // Show success message
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'Berhasil mengikuti ${_profileData!.username}'
                  : 'Berhenti mengikuti ${_profileData!.username}',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: _isFollowing ? Colors.green : Colors.orange,
          ),
        );
      } else if (mounted && !success) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Gagal memperbarui status follow. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle error
      print('Follow action error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildBottomSheetItem(Icons.link, 'Salin Link Profil', () {}),
            _buildBottomSheetItem(Icons.share, 'Bagikan Profil', () {}),
            _buildBottomSheetItem(Icons.report, 'Laporkan', () {}),
            _buildBottomSheetItem(Icons.block, 'Blokir Pengguna', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _profileData?.username ?? widget.username ?? 'Loading...',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _profileData?.username ?? widget.username ?? 'Loading...',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      );
    }

    // Show profile data
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [_buildProfileSection(), const SizedBox(height: 0)],
                ),
              ),
              _buildPostGridSliver(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
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
      title: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          children: [
            Text(
              _profileData?.username ?? widget.username ?? 'Loading...',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          onPressed: _showMoreOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag:
              'cover_${_profileData?.username ?? widget.username ?? 'Loading...'}',
          child: Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                  'https://i.pinimg.com/1200x/fb/23/03/fb2303e0fdae024825b9d15a3389e2da.jpg',
                ),
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
    if (_profileData == null) return const SizedBox();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'profile_${_profileData?.username ?? 'Loading...'}',
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
                    // ✅ Use real post count from API and real follow counts
                    _buildStatItem(
                        _userPosts.length.toString(), 'Postingan', null),
                    _buildStatItem(_formatCount(_followersCount), 'Pengikut',
                        () => _showFollowersList()),
                    _buildStatItem(_formatCount(_followingCount), 'Mengikuti',
                        () => _showFollowingList()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _profileData!.fullName.isNotEmpty
                          ? _profileData!.fullName
                          : _profileData!.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (_profileData!.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _profileData!.bio,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleFollowAction,
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
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isFollowing ? 'Mengikuti' : 'Ikuti',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showMessageDialog(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Pesan',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Kirim pesan ke ${_profileData?.fullName ?? _profileData?.username ?? 'Loading...'}',
        ),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Tulis pesan...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pesan terkirim ke ${_profileData?.fullName ?? _profileData?.username ?? 'Loading...'}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, VoidCallback? onTap) {
    final statWidget = Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: statWidget,
      );
    }

    return statWidget;
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
                  'Postingan akan muncul di sini',
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
          final post = _userPosts[index];
          return GestureDetector(
            onTap: () => _showImageDetail(post, index),
            child: Container(
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
                    Hero(
                      tag: 'post_$index',
                      child: Image.network(
                        post['media_url'] ??
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
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
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
                          if (post['caption'] != null &&
                              post['caption'].toString().isNotEmpty)
                            Text(
                              post['caption'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (post['location'] != null &&
                              post['location'].toString().isNotEmpty)
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
                                      post['location'].toString(),
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
                          if (post['is_video'] == 1)
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

  void _showImageDetail(Map<String, dynamic> post, int index) {
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
            title: Text(
              post['caption']?.toString() ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: Hero(
              tag: 'post_$index',
              child: InteractiveViewer(
                child: Image.network(
                  post['media_url'] ?? 'https://via.placeholder.com/400x400',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  // ✅ Add method to refresh follow counts after follow/unfollow
  Future<void> _refreshFollowCounts() async {
    if (_profileData != null) {
      try {
        final followCounts =
            await _followService.getFollowCounts(_profileData!.username);
        setState(() {
          _followersCount = followCounts['followers'] ?? 0;
          _followingCount = followCounts['following'] ?? 0;
        });
      } catch (e) {
        print('Error refreshing follow counts: $e');
      }
    }
  }

  // ✅ Add pull-to-refresh functionality
  Future<void> _onRefresh() async {
    await _loadProfileData();
  }

  // ✅ Show followers list
  void _showFollowersList() async {
    if (_profileData == null) return;

    try {
      final followers =
          await _followService.getFollowers(_profileData!.username);
      _showUserListDialog('Pengikut', followers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar pengikut: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ Show following list
  void _showFollowingList() async {
    if (_profileData == null) return;

    try {
      final following =
          await _followService.getFollowing(_profileData!.username);
      _showUserListDialog('Mengikuti', following);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar yang diikuti: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ Show user list dialog (followers/following)
  void _showUserListDialog(String title, List<dynamic> users) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profile_picture_url'] != null &&
                                user['profile_picture_url']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(user['profile_picture_url'])
                            : null,
                        child: user['profile_picture_url'] == null ||
                                user['profile_picture_url'].toString().isEmpty
                            ? Icon(Icons.person, color: Colors.grey[600])
                            : null,
                      ),
                      title: Text(
                        user['full_name']?.toString() ??
                            user['username']?.toString() ??
                            'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('@${user['username']?.toString() ?? ''}'),
                      onTap: () {
                        Navigator.pop(context);
                        if (user['username'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherProfilePage(
                                username: user['username'].toString(),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
