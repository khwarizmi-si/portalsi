// lib/controllers/home_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../models/paginated_response.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../services/announcement_service.dart';
import '../services/bookmark_service.dart';
import '../services/like_service.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';

class HomeController with ChangeNotifier {
  final PostService _postService = PostService();
  final AnnouncementService _announcementService = AnnouncementService();
  final StoryService _storyService = StoryService();
  final BookmarkService _bookmarkService = BookmarkService();
  final LikeService _likeService = LikeService();
  StreamSubscription? _likeUpdatesSubscription;

  List<dynamic> _feedItems = [];
  List<UserWithStories> _stories = [];
  List<Announcement> _pinnedAnnouncements = [];
  Post? _pinnedPost;

  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isFetchingMore = false;

  List<dynamic> get feedItems => _feedItems;
  bool get isFetchingMore => _isFetchingMore;
  List<UserWithStories> get stories => _stories;
  List<Announcement> get pinnedAnnouncements => _pinnedAnnouncements;
  Post? get pinnedPost => _pinnedPost;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const int _cacheDurationMinutes = 10;

  HomeController() {
    _initializeServices();
  }

  void _initializeServices() {
    // _likeService.connect();
    _likeUpdatesSubscription = _likeService.likeUpdates.listen((update) {
      final index = _feedItems.indexWhere((item) =>
      item is Map<String, dynamic> &&
          item['type'] == 'post' &&
          item['post_id'] == update.postId);

      if (index != -1) {
        final postMap = Map<String, dynamic>.from(_feedItems[index]);
        postMap['likes_count'] = update.likesCount;
        postMap['is_liked'] = update.isLiked;
        _feedItems[index] = postMap;
        notifyListeners();
      }
    });
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<T>> _loadFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    final cachedTimestamp = prefs.getInt('${key}_timestamp');
    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        final List<dynamic> jsonData = jsonDecode(cachedData);
        return jsonData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  Future<List<dynamic>> _loadRawListFromCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    final cachedTimestamp = prefs.getInt('${key}_timestamp');
    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        return jsonDecode(cachedData) as List<dynamic>;
      }
    }
    return [];
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --- 👇 PERUBAHAN 1: LOGIKA CACHE DIHAPUS 👇 ---
      // Logika sebelumnya yang memeriksa cache (`_loadFromCache`, `_loadRawListFromCache`)
      // dihapus dari sini agar selalu mengambil data baru dari server.
      await refreshDashboardData(isInitialLoad: true);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboardData({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      _isLoading = true;
    }
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final results = await Future.wait([
        _postService.fetchPosts(page: 1),
        _storyService.getStoryFeed(),
        _announcementService.refreshPinnedAnnouncements(),
        _postService.fetchPinnedPost(),
      ]);

      final paginatedResponse = results[0] as PaginatedFeedResponse;
      final storiesData = results[1] as List<dynamic>; // <-- Data mentah cerita
      final announcementsData = results[2] as List<Announcement>;
      final pinnedPostData = results[3] as Post?;

      // --- 👇 TAMBAHKAN LOG PENTING INI DI SINI 👇 ---
      log('--- 🕵️‍♂️ MENGINTIP DATA MENTAH STORY FEED SETELAH REFRESH ---');
      log(jsonEncode(storiesData));
      log('----------------------------------------------------------');
      // --- 👆 BATAS LOG 👆 ---

      _feedItems = paginatedResponse.feedItems;
      _hasNextPage = paginatedResponse.hasNextPage;
      _stories = storiesData.map((e) => UserWithStories.fromJson(e)).toList();
      _pinnedAnnouncements = announcementsData;
      _pinnedPost = pinnedPostData;

      // SIMPAN DATA BARU KE CACHE (KECUALI STORY)
      await _saveToCache('posts', _feedItems);
      // --- 👇 PERUBAHAN 2: PENYIMPANAN CACHE STORY DINONAKTIFKAN 👇 ---
      // await _saveToCache('stories', _stories.map((s) => s.toJson()).toList());
      await _saveToCache('announcements', _pinnedAnnouncements.map((a) => a.toJson()).toList());

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (isInitialLoad) {
        _isFetchingMore = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    if (_isFetchingMore || !_hasNextPage) return;
    _isFetchingMore = true;
    notifyListeners();
    _currentPage++;
    try {
      final response = await _postService.fetchPosts(page: _currentPage);
      _feedItems.addAll(response.feedItems);
      _hasNextPage = response.hasNextPage;
    } catch (e) {
      _currentPage--;
      print("Gagal memuat halaman selanjutnya: $e");
    }
    _isFetchingMore = false;
    notifyListeners();
  }

  // lib/controllers/home_controller.dart

  Future<void> toggleLike(int postId) async {
    final index = _feedItems.indexWhere((item) =>
    item is Map<String, dynamic> &&
        item['type'] == 'post' &&
        item['post_id'] == postId);

    if (index == -1) return;

    // 1. Ambil data asli. Kita beri nama 'originalLiked' dan 'originalCount'
    final postMap = Map<String, dynamic>.from(_feedItems[index]);
    final bool originalLiked = postMap['is_liked'] ?? false;
    final int originalCount = postMap['likes_count'] ?? 0;

    // 2. Pembaruan Optimis (langsung ubah UI)
    postMap['is_liked'] = !originalLiked;
    postMap['likes_count'] = originalCount + (!originalLiked ? 1 : -1);
    _feedItems[index] = postMap;
    notifyListeners();

    // 3. Panggil API
    try {
      await _likeService.toggleLikeHttp(
        postId,
        isCurrentlyLiked: originalLiked,     // <-- Menggunakan 'originalLiked'
        currentLikesCount: originalCount,   // <-- Menggunakan 'originalCount'
      );
    } catch (e) {
      // 4. Jika Gagal: Rollback (kembalikan ke data asli)

      // --- PERBAIKAN DI SINI ---
      // Pastikan Anda menggunakan nama yang sama dengan yang didefinisikan di atas
      postMap['is_liked'] = originalLiked;     // <-- HARUS 'originalLiked'
      postMap['likes_count'] = originalCount;  // <-- HARUS 'originalCount'
      // --- AKHIR PERBAIKAN ---

      _feedItems[index] = postMap;
      notifyListeners();
      print("Gagal toggle like di home: $e");
    }
  }

  Future<void> toggleBookmark(int postId) async {
    final itemIndex = feedItems.indexWhere((item) => item is Map && item['type'] == 'post' && item['post_id'] == postId);
    if (itemIndex == -1) return;
    final postMap = Map<String, dynamic>.from(feedItems[itemIndex] as Map);
    final currentStatus = postMap['is_bookmarked'] ?? false;
    postMap['is_bookmarked'] = !currentStatus;
    feedItems[itemIndex] = postMap;
    notifyListeners();
    try {
      if (postMap['is_bookmarked'] == true) {
        await _bookmarkService.addBookmark(postId);
      } else {
        await _bookmarkService.removeBookmark(postId);
      }
    } catch (e) {
      postMap['is_bookmarked'] = currentStatus;
      feedItems[itemIndex] = postMap;
      notifyListeners();
      print("Gagal mengubah bookmark: $e");
    }
  }

  @override
  void dispose() {
    _likeUpdatesSubscription?.cancel();
    // _likeService.disconnect();
    super.dispose();
  }
}