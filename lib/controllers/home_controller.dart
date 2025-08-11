// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/like_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../utils/secure_storage.dart';

class HomeController extends ChangeNotifier {
  // Gunakan singleton instance dari service
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeController() {
    fetchPosts();
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      // 1. Ambil data post utama
      _posts = await _postService.fetchAllPosts();
      _isLoading = false;
      notifyListeners();

      // 2. Ambil ID user yang sedang login (sebagai String?)
      final currentUserId = await SecureStorage.getUserId();

      // 3. Ambil data likes & comments untuk setiap post secara paralel
      await Future.wait(_posts.map((post) async {
        try {
          final results = await Future.wait([
            _likeService.getLikes(post.id),
            _commentService.getComments(post.id)
          ]);

          final likes = results[0] as List<Like>;
          final comments = results[1] as List<Comment>;

          // 4. Isi data ke dalam objek post
          post.likesCount = likes.length;
          post.commentsCount = comments.length;
          // Perbandingan sekarang aman: int vs int
          if (currentUserId != null) {
            post.isLikedByUser =
                likes.any((like) => like.user.id == currentUserId);
          }
        } catch (e) {
          debugPrint('Error fetching details for post ${post.id}: $e');
        }
      }));

      // 5. Beri tahu UI untuk terakhir kalinya agar update dengan data lengkap
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final originalLikedStatus = post.isLikedByUser;
    final originalLikesCount = post.likesCount;

    // Optimistic UI update
    post.isLikedByUser = !originalLikedStatus;
    post.likesCount += originalLikedStatus ? -1 : 1;
    notifyListeners();

    try {
      await _likeService.toggleLike(postId);
    } catch (e) {
      // Rollback jika gagal
      post.isLikedByUser = originalLikedStatus;
      post.likesCount = originalLikesCount;
      notifyListeners();
    }
  }
}
