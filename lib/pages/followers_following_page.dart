import 'package:flutter/material.dart';
import '../services/follow_service.dart';
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
    required this.followers,
    required this.following,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.initialTab;

    // Initialize dengan data yang diberikan
    followers = List.from(widget.followers);
    following = List.from(widget.following);

    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final userIdStr = await SecureStorage.getToken();
    currentUserId = int.tryParse(userIdStr ?? '');
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);

    try {
      final fetchedFollowers = await _followService.getFollowers(widget.userId);
      final fetchedFollowing = await _followService.getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          followers = fetchedFollowers;
          following = fetchedFollowing;
          isLoading = false;
          hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFollowAction(
      Map<dynamic, dynamic> user, bool isCurrentlyFollowing) async {
    final targetUserId = user['user_id'] ?? user['id'];
    if (targetUserId == null || currentUserId == null) return;

    // Optimistic update - update UI immediately
    setState(() {
      if (isCurrentlyFollowing) {
        // Unfollow - remove from following list
        following.removeWhere(
            (item) => (item['user_id'] ?? item['id']) == targetUserId);
      } else {
        // Follow - add to following list
        following.add(user);
      }
      hasChanges = true;
    });

    try {
      bool success;
      if (isCurrentlyFollowing) {
        success = await _followService.unfollowUser(targetUserId);
      } else {
        success = await _followService.followUser(targetUserId);
      }

      if (!success) {
        // Revert optimistic update if API call failed
        setState(() {
          if (isCurrentlyFollowing) {
            following.add(user);
          } else {
            following.removeWhere(
                (item) => (item['user_id'] ?? item['id']) == targetUserId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing
                ? 'Gagal unfollow user'
                : 'Gagal follow user'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing
                ? 'Berhasil unfollow user'
                : 'Berhasil follow user'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        if (isCurrentlyFollowing) {
          following.add(user);
        } else {
          following.removeWhere(
              (item) => (item['user_id'] ?? item['id']) == targetUserId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isUserFollowing(Map<dynamic, dynamic> user) {
    final targetUserId = user['user_id'] ?? user['id'];
    return following
        .any((item) => (item['user_id'] ?? item['id']) == targetUserId);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, hasChanges),
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
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: isLoading ? null : _refreshData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[600],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[600],
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
              Tab(
                text: 'Pengikut (${followers.length})',
              ),
              Tab(
                text: 'Mengikuti (${following.length})',
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowersTab ? Icons.people_outline : Icons.person_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFollowersTab
                  ? 'Belum ada pengikut'
                  : 'Belum mengikuti siapa pun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFollowersTab
                  ? 'Pengikut akan muncul di sini'
                  : 'Pengguna yang Anda ikuti akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index] as Map<dynamic, dynamic>;
          return _buildUserCard(user, isFollowersTab);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<dynamic, dynamic> user, bool isFollowersTab) {
    final userId = user['user_id'] ?? user['id'];
    final username = user['username'] ?? 'Unknown';
    final fullName = user['full_name'] ?? user['name'] ?? username;
    final profilePicture = user['profile_picture_url'] ??
        user['profile_picture'] ??
        'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg';
    final bio = user['bio'] ?? '';

    // Check if this user is being followed by current user
    final isFollowing = _isUserFollowing(user);
    final isCurrentUser = userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!, width: 1),
              image: DecorationImage(
                image: NetworkImage(profilePicture),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                if (fullName != username) ...[
                  const SizedBox(height: 2),
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Follow/Unfollow Button
          if (!isCurrentUser)
            SizedBox(
              width: 90,
              height: 32,
              child: ElevatedButton(
                onPressed: () => _handleFollowAction(user, isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.grey[200] : Colors.blue[600],
                  foregroundColor:
                      isFollowing ? Colors.grey[800] : Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color:
                          isFollowing ? Colors.grey[300]! : Colors.blue[600]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Mengikuti' : 'Ikuti',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Anda',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
