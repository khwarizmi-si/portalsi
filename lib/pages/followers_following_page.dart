import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../utils/navigation_helper.dart';
import '../utils/secure_storage.dart';

class FollowersFollowingPage extends StatefulWidget {
  final int userId;
  final int initialTab; // 0 = followers, 1 = following
  final List<dynamic> followers;
  final List<dynamic> following;

  const FollowersFollowingPage({
    Key? key,
    required this.userId,
    this.initialTab = 0,
    this.followers = const [], // Hapus 'required', beri nilai default
    this.following = const [], // Hapus 'required', beri nilai default
  }) : super(key: key);

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService();

  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isLoading = false;
  bool hasChanges = false;
  int? currentUserId;

  // Cache untuk optimasi network request
  final Set<int> _followingIds = <int>{};
  final Map<int, String?> _followingStatusMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.initialTab;

    _loadData();

    _getCurrentUserId();
  }

  void _initializeFollowingCache() {
    _followingIds.clear();
    for (final user in following) {
      final id = _extractUserId(user);
      if (id != null) _followingIds.add(id);
    }
  }

  void _initializeFollowingStatusMap() {
    _followingStatusMap.clear();
    for (final user in following) {
      final id = _extractUserId(user);
      final pivot = user['pivot'] as Map<dynamic, dynamic>?;
      final status = pivot?['status'] as String?;
      if (id != null) {
        _followingStatusMap[id] = status ?? 'accepted';
      }
    }
  }


  int? _extractUserId(Map<dynamic, dynamic> user) {
    return user['user_id'] as int? ?? user['id'] as int?;
  }

  Future<void> _getCurrentUserId() async {
    try {
      // Assuming getMyProfile returns a map with user ID.
      final myProfile = await _followService.getMyProfile();
      currentUserId = _extractUserId(myProfile);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (followers.isEmpty && following.isEmpty) {
      if (mounted) setState(() => isLoading = true);
    }

    try {
      final results = await Future.wait([
        _followService.getFollowers(widget.userId, forceRefresh: forceRefresh),
        _followService.getFollowing(widget.userId, forceRefresh: forceRefresh),
      ]);

      if (mounted) {
        setState(() {
          followers = results[0];
          following = results[1];
          _initializeFollowingCache();
          _initializeFollowingStatusMap();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData(forceRefresh: true);
  }

  Future<void> _handleFollowAction(
      Map<dynamic, dynamic> user, {required bool isUnfollow}) async {
    final targetUserId = _extractUserId(user);
    if (targetUserId == null || currentUserId == null) return;

    final button = context.findRenderObject();
    if (button != null && !button.attached) return;

    // Backup current state for potential revert
    final List<dynamic> originalFollowing = List.from(following);

    // Optimistic update
    setState(() {
      if (isUnfollow) {
        following.removeWhere((item) => _extractUserId(item) == targetUserId);
      } else {
        following.removeWhere((item) => _extractUserId(item) == targetUserId);
        final updatedUser = Map<dynamic, dynamic>.from(user);
        updatedUser['pivot'] = {'status': 'accepted'};
        following.add(updatedUser);
      }
      _initializeFollowingCache();
      _initializeFollowingStatusMap();
      hasChanges = true;
    });

    try {
      final success = isUnfollow
          ? await _followService.unfollowUser(targetUserId)
          : await _followService.followUser(targetUserId);

      if (!success) {
        // Revert on failure
        setState(() {
          following = originalFollowing;
          _initializeFollowingCache();
          _initializeFollowingStatusMap();
        });
        _showErrorSnackBar(isUnfollow ? 'Gagal unfollow' : 'Gagal mengikuti');
      }
    } catch (e) {
      // Revert on error
      setState(() {
        following = originalFollowing;
        _initializeFollowingCache();
        _initializeFollowingStatusMap();
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  bool _isUserFollowing(Map<dynamic, dynamic> user) {
    final targetUserId = _extractUserId(user);
    return targetUserId != null && _followingIds.contains(targetUserId);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToOtherProfile(int? userId, String username) {
    if (userId == null) return;

    Navigator.pushNamed(
      context,
      '/other-profile',
      arguments: {
        'userId': userId,
        'username': username,
      },
    );
  }

  Widget _buildProfileImage(String? profilePicture, String username) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      return Image.network(
        profilePicture,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(username);
        },
      );
    } else {
      return _buildDefaultAvatar(username);
    }
  }

  Widget _buildDefaultAvatar(String username) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.indigo, Colors.pink,
    ];
    final colorIndex = username.hashCode % colors.length;
    final color = colors[colorIndex.abs()];
    final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      color: color.shade100,
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Koneksi',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isLoading ? Colors.grey : Colors.black,
              ),
              onPressed: isLoading ? null : _refreshData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Pengikut (${followers.length})'),
              Tab(text: 'Mengikuti (${following.length})'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildUserList(followers, isFollowersTab: true),
            _buildUserList(following, isFollowersTab: false),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, {required bool isFollowersTab}) {
    if (users.isEmpty) {
      return _buildEmptyState(isFollowersTab);
    }
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = users[index] as Map<dynamic, dynamic>;
          return _buildUserCard(user, isFollowersTab);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isFollowersTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFollowersTab ? Icons.people_outline : Icons.person_add_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFollowersTab ? 'Belum ada pengikut' : 'Belum mengikuti siapa pun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFollowersTab
                  ? 'Pengikut akan muncul di sini ketika ada yang mengikuti Anda'
                  : 'Pengguna yang Anda ikuti akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<dynamic, dynamic> user, bool isFollowersTab) {
    final userId = _extractUserId(user);
    final username = user['username']?.toString() ?? 'Unknown';
    final fullName = user['full_name']?.toString() ?? user['name']?.toString() ?? username;
    final profilePicture = user['profile_picture_url']?.toString() ?? user['profile_picture']?.toString();
    final bio = user['bio']?.toString() ?? '';
    final isCurrentUser = userId == currentUserId;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCurrentUser
            ? null
            : () => Navigator.of(context).pop(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: isCurrentUser
                    ? null
                    : () => Navigator.of(context).pop(user),
                child: Hero(
                  tag: 'profile_$userId',
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipOval(
                      child: _buildProfileImage(profilePicture, username),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentUser
                      ? null
                      : () => Navigator.of(context).pop(user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (fullName != username) ...[
                        const SizedBox(height: 2),
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!isCurrentUser)
                if (isFollowersTab)
                  _buildFollowerTabButton(user)
                else
                  const SizedBox.shrink()
              else
                _buildCurrentUserBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerTabButton(Map<dynamic, dynamic> user) {
    final targetUserId = _extractUserId(user);
    final status = targetUserId != null ? _followingStatusMap[targetUserId] : null;

    String buttonText;
    bool isUnfollowAction;
    bool isAccepted = status == 'accepted';

    if (isAccepted) {
      buttonText = 'Diikuti';
      isUnfollowAction = true;
    } else {
      buttonText = 'Ikuti Balik';
      isUnfollowAction = false;
    }

    return SizedBox(
      width: 95,
      height: 36,
      child: ElevatedButton(
        onPressed: () => _handleFollowAction(user, isUnfollow: isUnfollowAction),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAccepted ? Colors.grey[100] : Theme.of(context).primaryColor,
          foregroundColor: isAccepted ? Colors.grey[700] : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isAccepted ? Colors.grey[300]! : Theme.of(context).primaryColor,
              width: 1,
            ),
          ),
        ),
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        'Anda',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}