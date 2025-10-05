// lib/pages/followers_following_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/verified_badge.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../utils/navigation_helper.dart';

class FollowersFollowingPage extends StatefulWidget {
  final int userId;
  final String username; // <-- 1. TAMBAHKAN VARIABLE INI
  final int initialTab;

  const FollowersFollowingPage({
    Key? key,
    required this.userId,
    required this.username, // <-- 2. JADIKAN REQUIRED DI CONSTRUCTOR
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService();

  List<User> followers = [];
  List<User> following = [];
  bool isLoading = false;
  int? currentUserId;

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final myProfileMap = await _followService.getMyProfile();
      final myProfileUser = User.fromJson(myProfileMap);
      currentUserId = myProfileUser.id;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
  }

  void _initializeFollowingCache() {
    _followingIds.clear();
    for (final user in following) {
      if (user.id != null) _followingIds.add(user.id!);
    }
  }

  void _initializeFollowingStatusMap() {
    _followingStatusMap.clear();
    for (final user in following) {
      if (user.id != null) {
        _followingStatusMap[user.id!] = 'accepted';
      }
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
          followers = results[0] as List<User>;
          following = results[1] as List<User>;
          _initializeFollowingCache();
          _initializeFollowingStatusMap();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Coba untuk muat ulang kembali');
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

  Future<void> _handleFollowAction(User user, {required bool isUnfollow}) async {
    final targetUserId = user.id;
    if (targetUserId == null || currentUserId == null) return;
    if (!mounted) return;

    final List<User> originalFollowing = List.from(following);

    setState(() {
      if (isUnfollow) {
        following.removeWhere((item) => item.id == user.id);
      } else {
        following.add(user);
      }
      _initializeFollowingCache();
      _initializeFollowingStatusMap();
    });

    try {
      final success = isUnfollow
          ? await _followService.unfollowUser(targetUserId)
          : await _followService.followUser(targetUserId);

      if (!success && mounted) {
        setState(() {
          following = originalFollowing;
          _initializeFollowingCache();
          _initializeFollowingStatusMap();
        });
        _showErrorSnackBar(isUnfollow ? 'Gagal berhenti mengikuti' : 'Gagal mengikuti');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          following = originalFollowing;
          _initializeFollowingCache();
          _initializeFollowingStatusMap();
        });
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
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

  Widget _buildProfileImage(String? profilePicture, String username) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      return Image.network(
        profilePicture,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: Colors.grey[200]);
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color.shade700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // --- 👇 3. GANTI TITLE DENGAN USERNAME DARI WIDGET 👇 ---
        title: Text(
          widget.username,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isLoading ? Colors.grey : Colors.black),
            onPressed: isLoading ? null : _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
    );
  }

  Widget _buildUserList(List<User> users, {required bool isFollowersTab}) {
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
          final user = users[index];
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
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(
                isFollowersTab ? Icons.people_outline : Icons.person_add_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFollowersTab ? 'Belum ada pengikut' : 'Belum mengikuti siapa pun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              isFollowersTab
                  ? 'Pengikut akan muncul di sini ketika ada yang mengikuti Anda'
                  : 'Pengguna yang Anda ikuti akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, bool isFollowersTab) {
    final userId = user.id;
    final username = user.username;
    final fullName = user.fullName ?? username;
    final profilePicture = user.profilePictureUrl;
    final bio = user.bio ?? '';
    final isCurrentUser = userId == currentUserId;

    void handleProfileTap() {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      NavigationHelper.navigateToProfile(context, user);
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCurrentUser ? null : handleProfileTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: isCurrentUser ? null : handleProfileTap,
                child: Hero(
                  tag: 'profile_$userId',
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipOval(child: _buildProfileImage(profilePicture, username)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentUser ? null : handleProfileTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          if (user.isVerified)
                            SizedBox(width: 6,),
                          if (user.isVerified)
                            const VerifiedBadge(size: 15),
                        ],
                      ),
                      if (fullName != username) ...[
                        const SizedBox(height: 2),
                        Text(
                          fullName,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w400),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.3),
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
                  _buildFollowingTabButton(user)
              else
                _buildCurrentUserBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerTabButton(User user) {
    final targetUserId = user.id;
    final isFollowing = targetUserId != null && _followingIds.contains(targetUserId);

    return SizedBox(
      width: 95,
      height: 36,
      child: ElevatedButton(
        onPressed: () => _handleFollowAction(user, isUnfollow: isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.grey[100] : Theme.of(context).primaryColor,
          foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isFollowing ? Colors.grey[300]! : Theme.of(context).primaryColor,
              width: 1,
            ),
          ),
        ),
        child: Text(
          isFollowing ? 'Diikuti' : 'Ikuti Balik',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFollowingTabButton(User user) {
    return SizedBox(
      width: 95,
      height: 36,
      child: OutlinedButton(
        onPressed: () => _handleFollowAction(user, isUnfollow: true),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Mengikuti',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700]),
      ),
    );
  }
}