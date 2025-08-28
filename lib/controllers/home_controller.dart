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

  List<Post> _posts = [];
  List<UserWithStories> _stories = [];
  List<Announcement> _pinnedAnnouncements = [];
  Post? _pinnedPost;

  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
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
    _likeService.connect(); // Memulai koneksi WebSocket

    // Mulai mendengarkan pembaruan dari LikeService
    _likeUpdatesSubscription = _likeService.likeUpdates.listen((update) {
      // Cari postingan yang sesuai di dalam daftar _posts
      final index = _posts.indexWhere((p) => p.id == update.postId);
      if (index != -1) {
        // Perbarui data postingan dan beri tahu UI
        _posts[index].likesCount = update.likesCount;
        _posts[index].isLikedByUser = update.isLiked;
        print("🔄 UI diperbarui untuk post #${update.postId}");
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

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cachedPosts = await _loadFromCache('posts', Post.fromJson);
      final cachedStories = await _loadFromCache('stories', UserWithStories.fromJson);
      final cachedAnnouncements = await _loadFromCache('announcements', Announcement.fromJson);

      if (cachedPosts.isNotEmpty || cachedStories.isNotEmpty || cachedAnnouncements.isNotEmpty) {
        _posts = cachedPosts;
        _stories = cachedStories;
        _pinnedAnnouncements = cachedAnnouncements;
        notifyListeners();
      }

      if (cachedPosts.isEmpty || cachedStories.isEmpty || cachedAnnouncements.isEmpty) {
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

      _posts = results[0] as List<Post>;
      _stories = (results[1] as List<dynamic>).map((e) => UserWithStories.fromJson(e)).toList();
      _pinnedAnnouncements = results[2] as List<Announcement>;
      _pinnedPost = results[3] as Post?;

      // --- 👇 PENAMBAHAN LOGGING DI SINI ---
      print("===== HASIL REFRESH DASHBOARD DATA =====");
      print("Posts: ${_posts.length} item");
      print("Stories: ${_stories.length} item");
      print("Pinned Announcements: ${_pinnedAnnouncements.length} item");
      print("Pinned Post: ${_pinnedPost != null ? 'Ada' : 'Tidak Ada'}");

      // Untuk melihat detail data dalam format JSON (bisa sangat panjang di console)
      // Uncomment baris di bawah ini jika Anda ingin melihat output JSON lengkapnya
      final jsonData = {
        // "posts": _posts.map((p) => p.toJson()).toList(),
        // "stories": _stories.map((s) => s.toJson()).toList(),
        "pinned_announcements": _pinnedAnnouncements.map((a) => a.toJson()).toList(),
      };
      print("Detail JSON: ${jsonEncode(jsonData)}");

      print("========================================");
      // -----------------------------------------

      await _saveToCache('posts', _posts.map((p) => p.toJson()).toList());
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
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      // Optimistic update
      post.isLikedByUser = !post.isLikedByUser;
      post.likesCount += post.isLikedByUser ? 1 : -1;
      notifyListeners();
    }

    // Kirim event ke server melalui WebSocket
    _likeService.toggleLikeSocket(postId);
    LikeService().toggleLikeHttp(postId);

  }

  @override
  void dispose() {
    // Hentikan langganan dan putuskan koneksi saat controller tidak lagi digunakan
    _likeUpdatesSubscription?.cancel();
    _likeService.disconnect();
    super.dispose();
  }
}