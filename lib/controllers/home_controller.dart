// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/like_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart'; // Import ProfileService untuk get user

class HomeController extends ChangeNotifier {
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();
  final ProfileService _profileService = ProfileService(); // Tambahkan ini

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  Post? _pinnedPost;
  Post? get pinnedPost => _pinnedPost;

  // [TAMBAHAN] State untuk menyimpan data pengguna yang sedang login
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeController() {
    fetchPosts();
  }

  // [PENYEMPURNAAN] Fungsi helper untuk mencari post dengan lebih mudah
  Post getPostById(int postId) {
    if (_pinnedPost?.id == postId) {
      return _pinnedPost!;
    }
    return _posts.firstWhere((p) => p.id == postId, orElse: () {
      throw Exception('Post dengan ID $postId tidak ditemukan.');
    });
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    // [PENYEMPURNAAN] Logika loading yang lebih sederhana
    _isLoading = true;
    if (isRefresh) _posts.clear(); // Kosongkan list jika refresh
    notifyListeners();

    _errorMessage = null;

    try {
      // Fetch user dan posts secara bersamaan untuk efisiensi
      final results = await Future.wait([
        _profileService.getProfile(),
        _postService.fetchAllPosts(),
      ]);

      _currentUser = results[0] as User;
      List<Post> allPosts = results[1] as List<Post>;

      // Logika Pinned Post Anda (sudah bagus, tidak diubah)
      final pinnedIndex = allPosts.indexWhere((p) => p.user.role == 'admin');
      if (pinnedIndex != -1) {
        _pinnedPost = allPosts.removeAt(pinnedIndex);
      } else {
        _pinnedPost = null;
      }
      _posts = allPosts;

      // Beri tahu UI bahwa post sudah ada (staged loading)
      _isLoading = false;
      notifyListeners();

      // Lanjutkan fetch detail likes/comments di background
      final List<Post> postsToProcess = [..._posts];
      if (_pinnedPost != null) {
        postsToProcess.add(_pinnedPost!);
      }

      await Future.wait(postsToProcess.map((post) async {
        try {
          final detailResults = await Future.wait([
            _likeService.getLikes(post.id),
            _commentService.getComments(post.id)
          ]);

          final likes = detailResults[0] as List<Like>;
          final comments = detailResults[1] as List<Comment>;

          post.likesCount = likes.length;
          post.commentsCount = comments.length;
          post.isLikedByUser =
              likes.any((like) => like.user.id == _currentUser?.id);
        } catch (e) {
          debugPrint('Error fetching details for post ${post.id}: $e');
        }
      }));

      // Beri tahu UI untuk terakhir kalinya dengan data lengkap
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      final post = getPostById(postId);
      // Optimistic UI update
      post.isLikedByUser = !post.isLikedByUser;
      post.isLikedByUser ? post.likesCount++ : post.likesCount--;
      notifyListeners();
      // Call service
      await _likeService.toggleLike(postId);
    } catch (e) {
      // Rollback jika gagal
      debugPrint("Gagal toggle like, melakukan rollback: $e");
      final post = getPostById(postId);
      post.isLikedByUser = !post.isLikedByUser;
      post.isLikedByUser ? post.likesCount++ : post.likesCount--;
      notifyListeners();
    }
  }

  // [TAMBAHAN] Fungsi untuk mengirim komentar
  Future<void> postComment(int postId, String content) async {
    try {
      // Panggil service untuk mengirim komentar
      await _commentService.addComment(postId, content);

      // Jika berhasil, update jumlah komentar di UI
      final post = getPostById(postId);
      post.commentsCount++;
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal mengirim komentar dari controller: $e");
      // Opsional: tampilkan notifikasi error ke pengguna
    }
  }
}
