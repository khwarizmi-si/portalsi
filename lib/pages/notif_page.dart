import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/bottom_navigation.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'dashboard_page.dart';
import 'other_profile_page.dart';
import 'post_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 3;
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();

  List<Map<String, dynamic>> _notifications = [];
  final Map<int, Map<String, dynamic>> _postCache = {};
  final Map<String, String> _userAvatarCache = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      await Future.wait([
        _preloadPostData(notifications),
        _preloadUserAvatars(notifications),
      ]);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat notifikasi. Silakan coba lagi.';
          _isLoading = false;
        });
      }
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _preloadPostData(
      List<Map<String, dynamic>> notifications) async {
    final postIds = <int>{};
    for (var notification in notifications) {
      final postId = notification['related_post_id'];
      if (postId is int && postId > 0) {
        postIds.add(postId);
      }
    }

    if (postIds.isEmpty) return;

    final futures = postIds.map((id) async {
      if (!_postCache.containsKey(id)) {
        try {
          final postDetail = await _postService.getPostDetail(id);
          if (postDetail != null) {
            _postCache[id] = postDetail;
          }
        } catch (e) {
          debugPrint('Error loading post $id: $e');
        }
      }
    });

    await Future.wait(futures);
  }

  Future<void> _preloadUserAvatars(
      List<Map<String, dynamic>> notifications) async {
    final usernames = <String>{};
    for (var notification in notifications) {
      final sender = notification['sender'];
      if (sender != null &&
          sender['username'] != null &&
          !_userAvatarCache.containsKey(sender['username'])) {
        usernames.add(sender['username']);
      }
    }

    if (usernames.isEmpty) return;

    final futures = usernames.map((username) async {
      try {
        final profile = await _profileService.getOtherProfile(username);
        _userAvatarCache[username] = profile.profilePictureUrl;
      } catch (e) {
        debugPrint('Error loading profile for $username: $e');
        _userAvatarCache[username] = '';
      }
    });

    await Future.wait(futures);
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      if (mounted) {
        setState(() {
          final index = _notifications
              .indexWhere((n) => n['notification_id'] == notificationId);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        setState(() {
          for (var notification in _notifications) {
            notification['is_read'] = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menandai semua sebagai sudah dibaca.')),
        );
      }
    }
  }

  void _navigateToPost(Map<String, dynamic> notification) async {
    final notificationId = notification['notification_id'];
    if (notificationId != null && !(notification['is_read'] ?? false)) {
      _markNotificationAsRead(notificationId);
    }

    final postId = notification['related_post_id'];
    if (postId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ID Post tidak valid.'), backgroundColor: Colors.red),
      );
      return;
    }

    final post = _postCache[postId];

    if (post != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            postId: postId,
            username: post['user']['username'] ?? 'Unknown',
            timeAgo: _formatTimeDifference(post['created_at']),
            imageUrl: _getPostMediaUrl(post),
            content: post['caption'] ?? '',
            likes: post['likes_count'] ?? 0,
            comments: post['comments_count'] ?? 0,
            profileImageUrl: post['user']['profile_picture_url'] ?? '',
            isVerified: post['user']['is_verified'] ?? false,
            isLiked: post['is_liked'] ?? false,
            userId: post['user']['id'] ?? 0,
            user: post['user'],
          ),
        ),
      ).then((_) => _loadNotifications()); // Refresh when returning
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Post tidak ditemukan.'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => OtherProfilePage(username: username)),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();

    for (var notification in _notifications) {
      final createdAt =
          DateTime.tryParse(notification['created_at'] ?? '') ?? now;
      final difference = now.difference(createdAt);

      String category;
      if (notification['type'] == 'mention') {
        category = 'Cerita Tentang Anda';
      } else if (difference.inHours < 24) {
        category = 'Hari Ini';
      } else if (difference.inDays == 1) {
        category = 'Kemarin';
      } else if (difference.inDays <= 7) {
        category = '7 hari terakhir';
      } else if (difference.inDays <= 30) {
        category = '30 hari terakhir';
      } else {
        category = 'Lebih lama';
      }

      grouped.putIfAbsent(category, () => []).add(notification);
    }
    return grouped;
  }

  String _formatTimeDifference(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}j';
    if (difference.inDays < 7) return '${difference.inDays}h';
    return DateFormat('dd MMM').format(date);
  }

  String _getPostMediaUrl(Map<String, dynamic> post) {
    if (post['media'] is List &&
        post['media'].isNotEmpty &&
        post['media'][0]['url'] != null) {
      return post['media'][0]['url'];
    }
    return post['image_url'] ??
        post['thumbnail_url'] ??
        post['media_url'] ??
        '';
  }

  String _getNotificationActionText(String type) {
    switch (type) {
      case 'like':
        return 'menyukai postingan Anda';
      case 'comment':
        return 'mengomentari postingan Anda';
      case 'follow':
        return 'mulai mengikuti Anda';
      case 'mention':
        return 'menyebutkan Anda dalam sebuah cerita';
      default:
        return 'melakukan sesuatu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_notifications.any((n) => !(n['is_read'] ?? false)))
            TextButton(
              onPressed: _markAllNotificationsAsRead,
              child: const Text('Tandai Semua',
                  style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() => _selectedIndex = index);
            if (index == 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _buildNotificationSections(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationSections() {
    final widgets = <Widget>[];
    final grouped = _groupNotifications();
    final sectionOrder = [
      'Cerita Tentang Anda',
      'Hari Ini',
      'Kemarin',
      '7 hari terakhir',
      '30 hari terakhir',
      'Lebih lama',
    ];

    for (final section in sectionOrder) {
      if (grouped.containsKey(section) && grouped[section]!.isNotEmpty) {
        widgets.add(_buildSectionHeader(section));
        widgets.add(const SizedBox(height: 12));

        for (final notification in grouped[section]!) {
          widgets.add(_NotificationItem(
            notification: notification,
            postCache: _postCache,
            userAvatarCache: _userAvatarCache,
            onPostTap: () => _navigateToPost(notification),
            onProfileTap: () {
              final sender = notification['sender'];
              if (sender != null && sender['username'] != null) {
                _navigateToProfile(sender['username']);
              }
            },
          ));
        }
        widgets.add(const SizedBox(height: 24));
      }
    }
    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}

// --- Separated NotificationItem Widget for Better Reusability ---

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Map<int, Map<String, dynamic>> postCache;
  final Map<String, String> userAvatarCache;
  final VoidCallback onPostTap;
  final VoidCallback onProfileTap;

  const _NotificationItem({
    Key? key,
    required this.notification,
    required this.postCache,
    required this.userAvatarCache,
    required this.onPostTap,
    required this.onProfileTap,
  }) : super(key: key);

  String _getNotificationActionText(String type) {
    switch (type) {
      case 'like':
        return 'menyukai postingan Anda';
      case 'comment':
        return 'mengomentari postingan Anda';
      case 'follow':
        return 'mulai mengikuti Anda';
      case 'mention':
        return 'menyebutkan Anda dalam sebuah cerita';
      default:
        return 'melakukan sesuatu';
    }
  }

  String _formatTimeDifference(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}j';
    if (difference.inDays < 7) return '${difference.inDays}h';
    return DateFormat('dd MMM').format(date);
  }

  String? _getPostThumbnail(Map<String, dynamic>? post) {
    if (post == null) return null;
    if (post['media'] is List &&
        post['media'].isNotEmpty &&
        post['media'][0]['url'] != null) {
      return post['media'][0]['url'];
    }
    return post['image_url'] ?? post['thumbnail_url'] ?? post['media_url'];
  }

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] ?? '';
    final isRead = notification['is_read'] ?? false;
    final sender = notification['sender'] ?? {};
    final username = sender['username'] ?? 'User';
    final avatarUrl = userAvatarCache[username] ??
        sender['profile_picture_url'] ??
        'https://via.placeholder.com/150';
    final postId = notification['related_post_id'];
    final post = postId is int ? postCache[postId] : null;

    final String actionText =
        notification['message'] ?? _getNotificationActionText(type);
    final String timeAgo = _formatTimeDifference(notification['created_at']);

    if (type == 'follow') {
      return _FollowNotificationItem(
        profileImage: avatarUrl,
        username: username,
        action: actionText,
        time: timeAgo,
        isRead: isRead,
        onTap: onProfileTap,
      );
    }

    final postThumbnail = _getPostThumbnail(post);
    final commentContent =
        notification['comment_content'] ?? notification['comment'];
    final postCaption =
        post?['caption'] ?? post?['content'] ?? post?['description'];

    return _StandardNotificationItem(
      profileImage: avatarUrl,
      username: username,
      action: actionText,
      time: timeAgo,
      isRead: isRead,
      contentImage: postThumbnail,
      commentContent: commentContent,
      postCaption: postCaption,
      onTap: onPostTap,
      onProfileTap: onProfileTap,
    );
  }
}

class _StandardNotificationItem extends StatelessWidget {
  final String profileImage;
  final String username;
  final String action;
  final String time;
  final bool isRead;
  final String? contentImage;
  final String? commentContent;
  final String? postCaption;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const _StandardNotificationItem({
    Key? key,
    required this.profileImage,
    required this.username,
    required this.action,
    required this.time,
    required this.isRead,
    this.contentImage,
    this.commentContent,
    this.postCaption,
    required this.onTap,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: !isRead ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 22,
                backgroundImage:
                    profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                backgroundColor: Colors.grey[300],
                child: profileImage.isEmpty
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $action'),
                      ],
                    ),
                  ),
                  if (commentContent?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '"$commentContent"',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (postCaption?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        postCaption!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            if (contentImage?.isNotEmpty ?? false)
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    contentImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowNotificationItem extends StatelessWidget {
  final String profileImage;
  final String username;
  final String action;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const _FollowNotificationItem({
    Key? key,
    required this.profileImage,
    required this.username,
    required this.action,
    required this.time,
    required this.isRead,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: !isRead ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              backgroundColor: Colors.grey[300],
              child: profileImage.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $action'),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Mengikuti',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
