// lib/services/comment_service.dart
import 'api_service.dart';
import '../models/comment_model.dart';
import 'package:flutter/foundation.dart';

class CommentService extends ApiService {
  // Singleton Pattern
  CommentService._internal();
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;

  // Logika cache Anda yang canggih tetap ada di sini.
  final Map<int, List<Comment>> _cache = {};
  final Map<int, DateTime> _cacheTime = {};
  static const Duration _cacheExpiration = Duration(minutes: 2);

  /// Mengambil comment, dengan mekanisme cache.
  Future<List<Comment>> getComments(int postId) async {
    if (_cache.containsKey(postId)) {
      final isCacheValid = _cacheTime[postId]
              ?.isAfter(DateTime.now().subtract(_cacheExpiration)) ??
          false;
      if (isCacheValid) {
        if (kDebugMode)
          print('💬 Menggunakan cache komentar untuk post $postId');
        return _cache[postId]!;
      }
    }

    try {
      final Map<String, dynamic> data = await get('posts/$postId/comments');
      final List<dynamic> commentList =
          data['comments'] ?? []; // Pastikan aman dari null
      final comments =
          commentList.map((item) => Comment.fromJson(item)).toList();

      // Simpan ke cache setelah berhasil fetch
      _cache[postId] = comments;
      _cacheTime[postId] = DateTime.now();
      return comments;
    } catch (e) {
      // Jika request gagal tapi ada cache lama (stale), kembalikan cache lama.
      if (_cache.containsKey(postId)) {
        if (kDebugMode)
          print('⚠️ Request gagal, menggunakan cache lama untuk post $postId');
        return _cache[postId]!;
      }
      rethrow; // Jika tidak ada cache sama sekali, lemparkan error.
    }
  }

  /// Mengirim komentar (optimistic, fire-and-forget).
  Future<bool> addComment(int postId, String content) async {
    // Langsung return true untuk UI yang responsif.
    // Proses pengiriman terjadi di background.
    post('posts/$postId/comments', body: {'content': content}).then((_) {
      // Jika sukses, hapus cache agar data berikutnya fresh.
      clearCache(postId);
      if (kDebugMode) print('✅ Komentar berhasil dikirim untuk post $postId');
    }).catchError((error) {
      if (kDebugMode)
        print('❌ Gagal mengirim komentar untuk post $postId: $error');
      // Di sini bisa ditambahkan logika untuk notifikasi kegagalan ke user.
    });
    return true;
  }

  /// Memperbarui komentar.
  Future<bool> editComment(int commentId, String newContent) async {
    await put('comments/$commentId', body: {'content': newContent});
    clearCache(); // Hapus semua cache karena kita tidak tahu post mana yg terpengaruh.
    return true;
  }

  /// Menghapus komentar.
  Future<bool> deleteComment(int commentId) async {
    await delete('comments/$commentId');
    clearCache();
    return true;
  }

  /// Utility untuk membersihkan cache secara manual.
  void clearCache([int? postId]) {
    if (postId != null) {
      _cache.remove(postId);
      _cacheTime.remove(postId);
    } else {
      _cache.clear();
      _cacheTime.clear();
    }
  }
}
