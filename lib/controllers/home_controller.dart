// lib/controllers/home_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../services/announcement_service.dart';
import '../services/like_service.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';

class HomeController with ChangeNotifier {
  final PostService _postService = PostService();
  final AnnouncementService _announcementService = AnnouncementService();
  final StoryService _storyService = StoryService();

  List<dynamic> _feedItems = []; // Sebelumnya: _posts

  List<UserWithStories> _stories = [];
  List<Announcement> _pinnedAnnouncements = [];
  Post? _pinnedPost;

  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get feedItems => _feedItems; // Sebelumnya: posts

  List<UserWithStories> get stories => _stories;
  List<Announcement> get pinnedAnnouncements => _pinnedAnnouncements;
  Post? get pinnedPost => _pinnedPost;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const int _cacheDurationMinutes = 10;

  final LikeService _likeService = LikeService();
  StreamSubscription? _likeUpdatesSubscription;

  HomeController() {
    _initializeServices();
  }

  void _initializeServices() {
    _likeService.connect();

    _likeUpdatesSubscription = _likeService.likeUpdates.listen((update) {
      // --- 👇 PERBAIKAN 1: Gunakan _feedItems, bukan _posts ---
      final index = _feedItems.indexWhere((item) =>
      item is Map<String, dynamic> &&
          item['type'] == 'post' &&
          item['post_id'] == update.postId);

      if (index != -1) {
        // Buat salinan map agar bisa diubah dan memicu UI update
        final postMap = Map<String, dynamic>.from(_feedItems[index]);
        postMap['likes_count'] = update.likesCount;
        postMap['is_liked'] = update.isLiked;
        _feedItems[index] = postMap;

        print("🔄 UI diperbarui via WebSocket untuk post #${update.postId}");

        notifyListeners();
      }
    });
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    print("📦 Data untuk '$key' disimpan ke cache.");
  }

  Future<List<T>> _loadFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    final cachedTimestamp = prefs.getInt('${key}_timestamp');

    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        print("✅ Memuat '$key' dari CACHE.");
        final List<dynamic> jsonData = jsonDecode(cachedData);
        return jsonData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      }
    }
    print("⚠️ Cache '$key' KOSONG/KADALUARSA.");
    return [];
  }

  // Fungsi baru ini khusus untuk memuat feed yang berisi mixed-types
  Future<List<dynamic>> _loadRawListFromCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    final cachedTimestamp = prefs.getInt('${key}_timestamp');

    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        print("✅ Memuat '$key' dari CACHE.");
        return jsonDecode(cachedData) as List<dynamic>;
      }
    }
    print("⚠️ Cache '$key' KOSONG/KADALUARSA.");
    return [];
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Panggil fungsi cache yang sesuai untuk setiap tipe data
      final cachedFeed = await _loadRawListFromCache('posts');
      final cachedStories = await _loadFromCache('stories', UserWithStories.fromJson);
      final cachedAnnouncements = await _loadFromCache('announcements', Announcement.fromJson);

      if (cachedFeed.isNotEmpty || cachedStories.isNotEmpty || cachedAnnouncements.isNotEmpty) {
        _feedItems = cachedFeed;

        _stories = cachedStories;
        _pinnedAnnouncements = cachedAnnouncements;
        notifyListeners();
      }

      if (cachedFeed.isEmpty || cachedStories.isEmpty || cachedAnnouncements.isEmpty) {

        await refreshDashboardData(isInitialLoad: true);
      }

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memaksa refresh semua data dari API dan memperbarui cache.
  Future<void> refreshDashboardData({bool isInitialLoad = false}) async {
    if (!isInitialLoad) {
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _postService.fetchPosts(page: 1),
        _storyService.getStoryFeed(),
        _announcementService.getPinnedAnnouncements(),
        _postService.fetchPinnedPost(),
      ]);

      _feedItems = results[0] as List<dynamic>;

      _stories = (results[1] as List<dynamic>).map((e) => UserWithStories.fromJson(e)).toList();
      _pinnedAnnouncements = results[2] as List<Announcement>;
      _pinnedPost = results[3] as Post?;

      print("===== HASIL REFRESH DASHBOARD DATA =====");
      print("Feed Items: ${_feedItems.length} item");
      print("Stories: ${_stories.length} item");
      print("Pinned Announcements: ${_pinnedAnnouncements.length} item");
      print("Pinned Post: ${_pinnedPost != null ? 'Ada' : 'Tidak Ada'}");
      print("========================================");

      await _saveToCache('posts', _feedItems);

      await _saveToCache('stories', _stories.map((s) => s.toJson()).toList());
      await _saveToCache('announcements', _pinnedAnnouncements.map((a) => a.toJson()).toList());

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if(isInitialLoad) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    final index = _feedItems.indexWhere((item) =>
    item is Map<String, dynamic> &&
        item['type'] == 'post' &&
        item['post_id'] == postId);

    if (index != -1) {
      final postMap = Map<String, dynamic>.from(_feedItems[index]);
      final isLiked = postMap['is_liked'] ?? false;
      final likesCount = postMap['likes_count'] ?? 0;

      postMap['is_liked'] = !isLiked;
      postMap['likes_count'] = likesCount + (!isLiked ? 1 : -1);

      _feedItems[index] = postMap;
      notifyListeners();
    }

    _likeService.toggleLikeSocket(postId);
    LikeService().toggleLikeHttp(postId);
  }

  @override
  void dispose() {

    _likeUpdatesSubscription?.cancel();
    _likeService.disconnect();
    super.dispose();
  }
}