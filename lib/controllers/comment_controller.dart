// lib/controllers/comment_controller.dart
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../utils/comment_utils.dart';

class CommentController extends ChangeNotifier {
  final int postId;

  // Gunakan singleton instance dari service
  final CommentService _commentService = CommentService();
  final ProfileService _profileService = ProfileService();

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

  CommentController({required this.postId}) {
    // Saat controller dibuat, langsung mulai ambil data
    _initialize();
  }

  /// Mengambil data awal yang dibutuhkan oleh halaman komentar.
  Future<void> _initialize() async {
    // Ambil data user dan komentar secara bersamaan untuk efisiensi
    await Future.wait([
      _loadCurrentUser(),
      loadComments(),
    ]);

    _isLoading = false;
    notifyListeners(); // Beri tahu UI bahwa loading selesai
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
    try {
      final fetchedComments = await _commentService.getComments(postId);
      // Urutkan komentar berdasarkan tanggal, yang terbaru di atas
      _comments = CommentUtils.sortCommentsByDate(fetchedComments);
    } catch (e) {
      _errorMessage = 'Gagal memuat komentar.';
      debugPrint("Error di loadComments: $e");
    }
    // Selalu panggil notifyListeners setelah ada perubahan data
    notifyListeners();
  }

  /// Menangani logika pengiriman komentar baru.
  Future<bool> submitComment(String content) async {
    // Validasi: jangan kirim jika kosong atau user tidak ada
    if (content.isEmpty || _currentUser == null) return false;

    // 1. Optimistic Update: Buat komentar "sementara" secara lokal
    final tempComment = CommentUtils.createTemporaryComment(
      postId: postId,
      content: content,
      username: _currentUser!.username,
    );

    // Langsung tambahkan ke daftar dan perbarui UI
    _comments.insert(0, tempComment);
    notifyListeners();

    try {
      // 2. Kirim komentar asli ke server di background
      await _commentService.addComment(postId, content);

      // 3. Jika berhasil, sinkronisasi ulang dengan server untuk mendapatkan
      //    data komentar yang asli (dengan ID dan timestamp dari server).
      await loadComments();
      return true;
    } catch (e) {
      // 4. Rollback: Jika pengiriman gagal, hapus komentar sementara
      _comments.removeWhere((c) => c.id == tempComment.id);
      _errorMessage = "Gagal mengirim komentar.";
      notifyListeners(); // Perbarui UI untuk menghapus komentar sementara
      return false;
    }
  }

  /// Menangani logika suka/batal suka pada komentar.
  void toggleCommentLike(int commentId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = _comments[index];
    comment.liked = !comment.liked;
    comment.likes += comment.liked ? 1 : -1;
    notifyListeners();

    // TODO: Panggil service untuk mengirim status like ke server di background
    // _commentService.toggleLike(commentId).catchError((e) { ... });
  }
}
