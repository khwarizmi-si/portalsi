import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../utils/navigation_helper.dart';
import '../pages/post_detail_page.dart';

// [TAMBAHKAN] Import FollowService
import '../services/follow_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  // [TAMBAHKAN] Buat instance FollowService
  final FollowService _followService = FollowService();

  static List<NotificationModel>? _cachedNotifications;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  // [TAMBAHKAN] State untuk melacak status follow
  Map<String, bool> followStatus = {};

  final Map<int, Post> _postCache = {};
  Map<int, Post> get postCache => _postCache;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {};
    for (var notification in _notifications) {
      final category = _getCategoryFor(notification.createdAt);
      if (grouped[category] == null) {
        grouped[category] = [];
      }
      grouped[category]!.add(notification);
    }
    return grouped;
  }

  String _getCategoryFor(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays < 7) return 'Minggu Ini';
    if (difference.inDays < 30) return 'Bulan Ini';
    return 'Lebih Awal';
  }

  NotificationController() {
    if (_cachedNotifications != null) {
      _notifications = _cachedNotifications!;
      _isLoading = false;
      // [TAMBAHKAN] Panggil inisialisasi status dari cache juga
      _initializeFollowStatuses(_notifications);
      fetchLatestNotifications();
    } else {
      loadInitialNotifications();
    }
  }

  Future<void> loadInitialNotifications() async {
    _isLoading = true;
    notifyListeners();
    await fetchLatestNotifications();
  }

  Future<void> refreshNotifications() async {
    await fetchLatestNotifications();
  }

  Future<void> fetchLatestNotifications() async {
    _errorMessage = null;
    try {
      final notificationData = await _notificationService.getNotifications();
      final newNotifications =
      notificationData.map((n) => NotificationModel.fromJson(n)).toList();

      _notifications = newNotifications;
      _cachedNotifications = newNotifications;

      await _preloadPostData(_notifications);
      // [TAMBAHKAN] Panggil inisialisasi status setelah data baru didapat
      await _initializeFollowStatuses(newNotifications);

    } catch (e) {
      if (_notifications.isEmpty) {
        _errorMessage = e.toString();
      }
      debugPrint("Gagal mengambil notifikasi terbaru: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [TAMBAHKAN] Fungsi untuk menginisialisasi status follow/unfollow
  Future<void> _initializeFollowStatuses(List<NotificationModel> notifications) async {
    // FollowService sudah memiliki cache, jadi ini efisien
    for (var notification in notifications) {
      if (notification.type == 'follow') {
        final isUserFollowing = await _followService.isFollowing(notification.sender.username);
        followStatus[notification.sender.username] = isUserFollowing;
      }
    }
  }

  // [TAMBAHKAN] Fungsi yang dipanggil UI saat tombol follow/unfollow diklik
  Future<void> toggleFollow(NotificationModel notification) async {
    final username = notification.sender.username;
    final currentlyFollowing = followStatus[username] ?? false;

    bool success;
    if (currentlyFollowing) {
      success = await _followService.unfollowUser(username);
    } else {
      success = await _followService.followUser(username);
    }

    if (success) {
      followStatus[username] = !currentlyFollowing;
      notifyListeners();
    }
    // Opsional: Tambahkan penanganan jika 'success' adalah false (misalnya, tampilkan snackbar error)
  }

  Future<void> _preloadPostData(List<NotificationModel> notifications) async {
    final postIds = notifications
        .where((n) =>
    n.relatedPostId != null && !_postCache.containsKey(n.relatedPostId))
        .map((n) => n.relatedPostId!)
        .toSet();

    if (postIds.isEmpty) return;

    await Future.wait(postIds.map((id) async {
      try {
        final post = await _postService.getPostDetail(id);
        _postCache[id] = post;
      } catch (e) {
        debugPrint('Gagal preload post $id: $e');
      }
    }));
  }

  void onNotificationTapped(
      BuildContext context, NotificationModel notification) {
    if (!notification.isRead) {
      notification.isRead = true;
      notifyListeners();
      _notificationService.markAsRead(notification.id).catchError((e) {
        notification.isRead = false;
        notifyListeners();
      });
    }

    if (notification.type == 'follow') {
      NavigationHelper.navigateToProfile(context, notification.sender.toJson());
    } else if (notification.relatedPostId != null) {
      final post = _postCache[notification.relatedPostId];
      if (post != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                postId: post.id,
                username: post.user.username,
                profileImageUrl: post.user.profilePictureUrl,
                timeAgo: post.createdAt.toIso8601String(),
                imageUrl: post.mediaUrl ?? '',
                content: post.caption,
                comments: post.commentsCount,
                likes: post.likesCount,
                isVerified: post.user.isVerified,
                isLiked: post.isLikedByUser,
                initialPost: post,
              ),
            ));
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      for (var n in _notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal menandai semua notifikasi: $e");
    }
  }
}