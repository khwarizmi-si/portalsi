// lib/controllers/notification_controller.dart
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../services/notification_service.dart'; // Buat service ini
import '../services/post_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final PostService _postService = PostService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  // Cache untuk data post yang terkait notifikasi
  final Map<int, Post> _postCache = {};
  Map<int, Post> get postCache => _postCache;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
      _isLoading = false;
      notifyListeners();

      // Preload data post terkait di background
      _preloadPostData(_notifications);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _preloadPostData(List<NotificationModel> notifications) async {
    final postIds = notifications
        .where((n) =>
            n.relatedPostId != null && !_postCache.containsKey(n.relatedPostId))
        .map((n) => n.relatedPostId!)
        .toSet(); // Ambil ID unik yang belum di-cache

    if (postIds.isEmpty) return;

    await Future.wait(postIds.map((id) async {
      try {
        final post = await _postService.getPostDetail(id);
        _postCache[id] = post;
      } catch (e) {
        debugPrint('Gagal preload post $id: $e');
      }
    }));

    // Beri tahu UI bahwa ada data baru di cache
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      for (var n in _notifications) {
        n.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      // Handle error, mungkin dengan state error terpisah
      debugPrint("Gagal menandai semua notifikasi: $e");
    }
  }
}
