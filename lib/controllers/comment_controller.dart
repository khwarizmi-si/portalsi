// lib/controllers/comment_controller.dart
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/comment_like_service.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../utils/comment_utils.dart';

class CommentController extends ChangeNotifier {
  final int postId;
  final CommentLikeService _commentLikeService = CommentLikeService();
  List<Comment> _originalComments;

  bool _isDisposed = false;
  // Gunakan singleton instance dari service
  final CommentService _commentService = CommentService();
  final ProfileService _profileService = ProfileService();

  Comment? _replyingToComment;
  Comment? get replyingToComment => _replyingToComment;

  // STATE: Daftar komentar
  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  // STATE: Data user yang sedang login
  User? _currentUser;
  User? get currentUser => _currentUser;

  // STATE: Status loading dan error
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CommentController({required this.postId, required List<Comment> initialComments})
      : _originalComments = initialComments {
    // Proses komentar awal, lalu muat data user
    _comments = CommentUtils.flattenComments(_originalComments);
    _isLoading = true; // Set loading untuk proses ambil data user
    _initialize();
  }

  void setReplyingTo(Comment? comment) {
    _replyingToComment = comment;
    notifyListeners(); // Beri tahu UI untuk update
  }

  Future<void> toggleCommentLike(Comment comment) async {
    final originalLikedStatus = comment.liked;
    final originalLikesCount = comment.likes;

    final index = _comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    // 1. Optimistic Update (tetap sama)
    _comments[index].liked = !originalLikedStatus;
    _comments[index].likes += originalLikedStatus ? -1 : 1;
    notifyListeners();

    // --- 👇 2. LOGIKA KONTROL SEKARANG ADA DI SINI 👇 ---
    try {
      bool success;
      if (_comments[index].liked) {
        // Jika UI sekarang dalam status liked, panggil service untuk like
        success = await _commentLikeService.likeComment(comment.id);
      } else {
        // Jika UI sekarang dalam status unliked, panggil service untuk unlike
        success = await _commentLikeService.unlikeComment(comment.id);
      }

      if (!success) {
        throw Exception('Server failed to process the request.');
      }
    } catch (e) {
      // 3. Fallback (tetap sama)
      if (!_isDisposed) {
        _comments[index].liked = originalLikedStatus;
        _comments[index].likes = originalLikesCount;
        notifyListeners();
      }
    }
  }

  /// Mengambil data awal yang dibutuhkan oleh halaman komentar.
  Future<void> _initialize() async {
    // --- 👇 PERUBAHAN UTAMA DI SINI 👇 ---
    // Kita jalankan kedua proses ini secara bersamaan untuk efisiensi
    await Future.wait([
      _loadCurrentUser(), // Tetap ambil data user
      loadComments(),     // Panggil fungsi untuk memuat komentar dari server
    ]);

    _isLoading = false; // Hentikan loading setelah semua data siap
    // notifyListeners(); //tidak perlu di sini karena sudah dipanggil di dalam loadComments()
  }

  @override
  void dispose() {
    _isDisposed = true; // Set flag menjadi true saat di-dispose
    super.dispose();
  }

  /// Mengambil data profil user yang sedang login.
  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _profileService.getProfile();
      _currentUser = User(
        id: profile.id,
        username: profile.username,
        email: profile.email,
        fullName: profile.fullName,
        bio: profile.bio,
        profilePictureUrl: profile.profilePictureUrl,
        isVerified: profile.isVerified,
      );
    } catch (e) {
      debugPrint("Gagal memuat data user: $e");
      // Buat user fallback jika gagal
      _currentUser = User(id: 0, username: 'Anda');
    }
  }

  /// Mengambil daftar komentar dari server.
  Future<void> loadComments() async {
    _errorMessage = null;
    notifyListeners();
    try {
      // Panggil PostService untuk mendapatkan detail post TERBARU
      // Asumsi Anda punya PostService.getPostDetail(postId)
      // final post = await PostService().getPostDetail(postId);
      // _originalComments = post.comments;

      // Untuk sementara, kita pakai lagi CommentService sebagai fallback refresh
      final fetchedComments = await _commentService.getComments(postId);

      // Proses dan ratakan komentar yang baru di-refresh
      _comments = CommentUtils.flattenComments(fetchedComments);
    } catch (e) {
      _errorMessage = 'Gagal memuat ulang komentar.';
      debugPrint("Error di loadComments: $e");
    }
    notifyListeners();
  }

  /// Menangani logika pengiriman komentar baru.
  Future<bool> postComment(String content) async {
    if (content.isEmpty || _currentUser == null) return false;

    final tempComment = CommentUtils.createTemporaryComment(
      postId: postId,
      content: content,
      username: _currentUser!.username,
    );
    _comments.insert(0, tempComment);
    notifyListeners();

    try {
      // Cek apakah kita sedang membalas atau membuat komentar baru
      if (_replyingToComment != null) {
        await _commentService.addCommentReply(postId, content, _replyingToComment!.id);
      } else {
        await _commentService.addComment(postId, content);
      }

      // Setelah berhasil, reset mode membalas dan muat ulang komentar
      setReplyingTo(null);
      await loadComments();
      return true;
    } catch (e) {
      _comments.removeWhere((c) => c.id == tempComment.id);
      _errorMessage = "Gagal mengirim balasan.";

      // Tetap reset mode membalas walaupun gagal
      setReplyingTo(null);
      notifyListeners();
      return false;
    }
  }
}
