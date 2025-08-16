// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
// Import Like dan Comment model tidak lagi diperlukan di sini
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';

class HomeController extends ChangeNotifier {
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();
  final ProfileService _profileService = ProfileService();

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  Post? _pinnedPost;
  Post? get pinnedPost => _pinnedPost;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // State untuk paginasi
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeController() {
    fetchPosts(isRefresh: true);
  }

  Post getPostById(int postId) {
    if (_pinnedPost?.id == postId) {
      return _pinnedPost!;
    }
    return _posts.firstWhere((p) => p.id == postId, orElse: () {
      throw Exception('Post dengan ID $postId tidak ditemukan.');
    });
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    _isLoading = true;
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts.clear();
      _pinnedPost = null;
    }
    notifyListeners();

    _errorMessage = null;

    try {
      // Cukup panggil API user dan posts. Data like/comment sudah lengkap.
      final results = await Future.wait([
        _profileService.getProfile(),
        _postService.fetchPosts(
            page: 1), // [DIUBAH] Memastikan selalu mulai dari halaman 1
      ]);

      _currentUser = results[0] as User;
      List<Post> allPosts = results[1] as List<Post>;

      final pinnedIndex = allPosts.indexWhere((p) => p.user.role == 'admin');
      if (pinnedIndex != -1) {
        _pinnedPost = allPosts.removeAt(pinnedIndex);
      }

      _posts = allPosts;
      _currentPage = 1;
      _hasMore = allPosts.isNotEmpty;

      // [OPTIMASI] Seluruh blok untuk mengambil detail like/comment per post DIHAPUS
      // karena tidak lagi diperlukan. Ini menyelesaikan masalah N+1 dan error 429.
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newPosts = await _postService.fetchPosts(page: _currentPage);
      if (newPosts.isEmpty) {
        _hasMore = false;
      } else {
        _posts.addAll(newPosts);
      }
    } catch (e) {
      _currentPage--; // Kembalikan nomor halaman jika gagal
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    final post = getPostById(postId);
    // Optimistic UI update
    post.isLikedByUser = !post.isLikedByUser;
    post.isLikedByUser ? post.likesCount++ : post.likesCount--;
    notifyListeners();

    try {
      await _likeService.toggleLike(postId);
    } catch (e) {
      debugPrint("Gagal toggle like, melakukan rollback: $e");
      // Rollback jika gagal
      post.isLikedByUser = !post.isLikedByUser;
      post.isLikedByUser ? post.likesCount++ : post.likesCount--;
      notifyListeners();
    }
  }

  Future<void> postComment(int postId, String content) async {
    try {
      await _commentService.addComment(postId, content);
      final post = getPostById(postId);
      post.commentsCount++;
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal mengirim komentar dari controller: $e");
    }
  }
}
