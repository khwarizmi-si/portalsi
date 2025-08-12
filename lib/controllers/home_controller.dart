// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart'; // <-- PASTIKAN USER MODEL DI-IMPORT
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

  // State baru untuk menampung pinned post
  Post? _pinnedPost;
  Post? get pinnedPost => _pinnedPost;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeController() {
    fetchPosts();
  }

  Future<void> fetchPosts({bool isRefresh = false}) async {
    if (!isRefresh && _posts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      // 1. Ambil semua data post dari service
      List<Post> allPosts = await _postService.fetchAllPosts();

      // --- LOGIKA BARU: PISAHKAN PINNED POST ---
      // Cari postingan pertama yang dibuat oleh admin.
      // Anda bisa menyesuaikan kondisi ini, misal dengan flag `post.isPinned`.
      // Di sini kita asumsikan user admin punya role 'admin'.
      final pinnedIndex = allPosts.indexWhere((p) => p.user.role == 'admin');

      if (pinnedIndex != -1) {
        // Jika ditemukan, pindahkan ke state _pinnedPost
        _pinnedPost = allPosts[pinnedIndex];
        // Hapus dari daftar utama agar tidak duplikat
        allPosts.removeAt(pinnedIndex);
      } else {
        // Jika tidak ada post dari admin, pastikan _pinnedPost kosong
        _pinnedPost = null;
      }

      _posts = allPosts; // Sisa post menjadi daftar biasa
      // --- AKHIR LOGIKA BARU ---

      _isLoading = false;
      // Beri tahu UI bahwa daftar post utama sudah siap (tanpa detail like/comment)
      notifyListeners();

      // 2. Ambil ID user yang sedang login
      final currentUserId = await SecureStorage.getUserId();

      // 3. Buat daftar gabungan untuk mengambil detail like & comment
      // Ini memastikan pinned post juga mendapatkan detailnya.
      final List<Post> postsToProcess = [..._posts];
      if (_pinnedPost != null) {
        postsToProcess.add(_pinnedPost!);
      }

      // 4. Ambil data likes & comments untuk setiap post secara paralel
      await Future.wait(postsToProcess.map((post) async {
        try {
          final results = await Future.wait([
            _likeService.getLikes(post.id),
            _commentService.getComments(post.id)
          ]);

          final likes = results[0] as List<Like>;
          final comments = results[1] as List<Comment>;

          // 5. Isi data ke dalam objek post
          post.likesCount = likes.length;
          post.commentsCount = comments.length;
          if (currentUserId != null) {
            post.isLikedByUser =
                likes.any((like) => like.user.id == currentUserId);
          }
        } catch (e) {
          debugPrint('Error fetching details for post ${post.id}: $e');
        }
      }));

      // 6. Beri tahu UI untuk terakhir kalinya agar update dengan data lengkap
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    // --- LOGIKA BARU: Cari post di kedua daftar (biasa dan pinned) ---
    Post? post;
    int postIndex = _posts.indexWhere((p) => p.id == postId);

    if (postIndex != -1) {
      // Post ditemukan di daftar biasa
      post = _posts[postIndex];
    } else if (_pinnedPost != null && _pinnedPost!.id == postId) {
      // Post ditemukan sebagai pinned post
      post = _pinnedPost;
    }

    // Jika post tidak ditemukan di mana pun, keluar dari fungsi
    if (post == null) return;
    // --- AKHIR LOGIKA BARU ---

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
