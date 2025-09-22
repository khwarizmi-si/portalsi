import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../utils/navigation_helper.dart';
import '../pages/post_detail_page.dart';
import '../services/follow_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();
  final FollowService _followService = FollowService();

  static List<NotificationModel>? _cachedNotifications;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  Map<String, bool> followStatus = {};

  final Map<int, Post> _postCache = {};
  Map<int, Post> get postCache => _postCache;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  /// Getter utama yang berisi logika pengelompokan baru
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    // Helper untuk membandingkan tanggal tanpa memperhitungkan waktu
    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notification in _notifications) {
      final notificationDate = notification.createdAt;

      if (isSameDay(notificationDate, today)) {
        (grouped['Hari Ini'] ??= []).add(notification);
      } else if (isSameDay(notificationDate, yesterday)) {
        (grouped['Kemarin'] ??= []).add(notification);
      } else if (now.difference(notificationDate).inDays < 7) {
        (grouped['7 Hari Terakhir'] ??= []).add(notification);
      } else if (now.difference(notificationDate).inDays < 30) {
        (grouped['30 Hari Terakhir'] ??= []).add(notification);
      } else {
        (grouped['Lebih lama'] ??= []).add(notification);
      }
    }
    return grouped;
  }

  NotificationController() {
    if (_cachedNotifications != null) {
      _notifications = _cachedNotifications!;
      _isLoading = false;
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

  Future<void> _initializeFollowStatuses(List<NotificationModel> notifications) async {
    for (var notification in notifications) {
      if (notification.type == 'follow') {
        // Asumsi FollowService memiliki metode isFollowing
        // final isUserFollowing = await _followService.isFollowing(notification.sender.username);
        // followStatus[notification.sender.username] = isUserFollowing;
      }
    }
  }

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
      Navigator.pop(context);
      NavigationHelper.navigateToProfile(context, notification.sender.toJson());
    } else if (notification.relatedPostId != null) {
      final post = _postCache[notification.relatedPostId];
      if (post != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                postId: post.id,
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