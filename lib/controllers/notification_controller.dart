import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../utils/navigation_helper.dart'; // Impor helper navigasi
import '../pages/post_detail_page.dart'; // Impor halaman detail

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  final Map<int, Post> _postCache = {};
  Map<int, Post> get postCache => _postCache;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Getter untuk memeriksa apakah ada notifikasi yang belum dibaca
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
    loadNotifications();
  }

  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      final notificationData = await _notificationService.getNotifications();
      _notifications =
          notificationData.map((n) => NotificationModel.fromJson(n)).toList();
      await _preloadPostData(_notifications);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
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
    notifyListeners();
  }

  /// Aksi saat notifikasi di-tap.
  void onNotificationTapped(
      BuildContext context, NotificationModel notification) {
    // 1. Tandai sebagai sudah dibaca (optimistic update)
    if (!notification.isRead) {
      notification.isRead = true;
      notifyListeners();
      _notificationService.markAsRead(notification.id).catchError((e) {
        // Jika gagal, kembalikan statusnya (opsional)
        notification.isRead = false;
        notifyListeners();
      });
    }

    // 2. Lakukan navigasi berdasarkan tipe notifikasi
    if (notification.type == 'follow') {
      NavigationHelper.navigateToProfile(context, notification.sender.toJson());
    } else if (notification.relatedPostId != null) {
      final post = _postCache[notification.relatedPostId];
      if (post != null) {
        // Navigasi ke halaman detail post
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

  /// Aksi untuk menandai semua sebagai sudah dibaca
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
