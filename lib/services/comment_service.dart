// lib/services/comment_service.dart

import 'package:http/http.dart' as http;

import '../utils/secure_storage.dart';
import 'api_service.dart';
import '../models/comment_model.dart';
import 'package:flutter/foundation.dart';

class CommentService extends ApiService {
  // Singleton Pattern
  CommentService._internal();

  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;

  // Cache
  final Map<int, List<Comment>> _cache = {};
  final Map<int, DateTime> _cacheTime = {};
  static const Duration _cacheExpiration = Duration(minutes: 2);

  /// Ambil komentar dengan cache
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
      final List<dynamic> commentList = data['comments'] ?? [];
      final comments =
          commentList.map((item) => Comment.fromJson(item)).toList();

      _cache[postId] = comments;
      _cacheTime[postId] = DateTime.now();
      return comments;
    } catch (e) {
      if (_cache.containsKey(postId)) {
        if (kDebugMode)
          print('⚠️ Request gagal, menggunakan cache lama untuk post $postId');
        return _cache[postId]!;
      }
      rethrow;
    }
  }

  Future<Comment> addCommentReply(int postId, String content, int parentCommentId) async {
    try {
      final responseData = await post(
        'posts/$postId/comments',
        body: {
          'content': content,
          'parent_comment_id': parentCommentId.toString(), // Sesuai API
        },
      );

      final newComment = Comment.fromJson(responseData['data']);
      clearCache(postId); // Hapus cache agar balasan baru muncul saat refresh

      if (kDebugMode) print('✅ Balasan berhasil dikirim untuk komentar $parentCommentId');

      return newComment;
    } catch (e) {
      if (kDebugMode) print('❌ Gagal mengirim balasan untuk komentar $parentCommentId: $e');
      rethrow;
    }
  }

  /// Kirim komentar dan emit ke socket
  Future<Comment> addComment(int postId, String content) async {
    try {
      final responseData =
          await post('posts/$postId/comments', body: {'content': content});

      final newComment = Comment.fromJson(responseData['data']);
      clearCache(postId);

      if (kDebugMode) print('✅ Komentar berhasil dikirim untuk post $postId');

      // 🔹 Emit realtime ke Socket.IO

      return newComment;
    } catch (e) {
      if (kDebugMode) print('❌ Gagal mengirim komentar untuk post $postId: $e');
      rethrow;
    }
  }

  /// Edit komentar
  Future<bool> editComment(int commentId, String newContent) async {
    await put('comments/$commentId', body: {'content': newContent});
    clearCache(); // Hapus semua cache
    return true;
  }

  /// Hapus komentar
  Future<bool> deleteComment(int commentId) async {
    await delete('comments/$commentId');
    clearCache();
    return true;
  }

  /// Bersihkan cache
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
