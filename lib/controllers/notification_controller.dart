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

  // [MODIFIKASI 1] Tambahkan variabel cache statis.
  // 'static' berarti variabel ini akan bertahan nilainya selama aplikasi berjalan,
  // bahkan jika halaman notifikasi ditutup dan dibuka kembali.
  static List<NotificationModel>? _cachedNotifications;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

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

  // [MODIFIKASI 2] Ubah konstruktor untuk logika cache.
  NotificationController() {
    // Cek apakah ada data di cache.
    if (_cachedNotifications != null) {
      // Jika ada, langsung gunakan data cache untuk tampilan awal.
      _notifications = _cachedNotifications!;
      _isLoading = false; // Data sudah siap, jadi tidak perlu loading screen.

      // Kemudian, panggil API di latar belakang untuk mendapatkan data terbaru.
      fetchLatestNotifications();
    } else {
      // Jika tidak ada cache (pembukaan pertama kali), panggil API dengan state loading.
      loadInitialNotifications();
    }
  }

  // [MODIFIKASI 3] Buat metode terpisah untuk pengambilan data awal (dengan loader).
  Future<void> loadInitialNotifications() async {
    _isLoading = true;
    notifyListeners(); // Tampilkan CircularProgressIndicator di UI
    await fetchLatestNotifications();
  }

  // [MODIFIKASI 4] Ganti nama metode 'loadNotifications' menjadi 'refreshNotifications'
  // Metode ini digunakan untuk fitur pull-to-refresh dan tidak menampilkan loader layar penuh.
  Future<void> refreshNotifications() async {
    await fetchLatestNotifications();
  }

  // [MODIFIKASI 5] Buat metode inti untuk mengambil data dari API.
  // Metode ini akan dipanggil oleh semua skenario (awal, background, refresh).
  Future<void> fetchLatestNotifications() async {
    _errorMessage = null;
    try {
      // 1. Ambil data baru dari service.
      final notificationData = await _notificationService.getNotifications();
      final newNotifications =
      notificationData.map((n) => NotificationModel.fromJson(n)).toList();

      // 2. Perbarui state notifikasi utama yang akan ditampilkan di UI.
      _notifications = newNotifications;

      // 3. Simpan data baru yang berhasil didapat ke dalam cache.
      _cachedNotifications = newNotifications;

      await _preloadPostData(_notifications);
    } catch (e) {
      // Hanya tampilkan pesan error jika tidak ada data sama sekali (bahkan dari cache).
      if (_notifications.isEmpty) {
        _errorMessage = e.toString();
      }
      debugPrint("Gagal mengambil notifikasi terbaru: $e");
    } finally {
      // Hentikan state loading (jika sedang aktif) dan perbarui UI.
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
    // Tidak perlu notifyListeners() di sini karena sudah dipanggil di fetchLatestNotifications()
  }

  /// Aksi saat notifikasi di-tap.
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