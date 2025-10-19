// lib/services/bookmark_service.dart
import 'dart:async'; // <-- TAMBAHKAN
import 'package:flutter/foundation.dart'; // <-- TAMBAHKAN
import 'package:rxdart/rxdart.dart'; // <-- TAMBAHKAN
import 'api_service.dart';
import '../models/post_model.dart';

// --- 👇 TAMBAHKAN KELAS BARU UNTUK DATA UPDATE 👇 ---
class BookmarkUpdate {
  final int postId;
  final bool isBookmarked;

  BookmarkUpdate({required this.postId, required this.isBookmarked});
}
// --- 👆 AKHIR TAMBAHAN 👆 ---

class BookmarkService extends ApiService {
  BookmarkService._internal();
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;

  // --- 👇 TAMBAHKAN STREAM CONTROLLER 👇 ---
  final BehaviorSubject<BookmarkUpdate> _streamController =
  BehaviorSubject<BookmarkUpdate>();
  Stream<BookmarkUpdate> get bookmarkUpdates => _streamController.stream;
  // --- 👆 AKHIR TAMBAHAN 👆 ---


  /// Menambahkan post ke bookmark
  Future<bool> addBookmark(int postId) async {
    try {
      await post('bookmarks/$postId');
      debugPrint('✅ Post $postId berhasil ditambahkan ke bookmark.');

      // --- 👇 TAMBAHKAN PUSH KE STREAM 👇 ---
      _streamController.add(BookmarkUpdate(postId: postId, isBookmarked: true));
      // --- 👆 AKHIR TAMBAHAN 👆 ---

      return true;
    } catch (e) {
      debugPrint('❌ Gagal menambahkan bookmark untuk post $postId: $e');
      rethrow;
    }
  }

  /// Menghapus post dari bookmark
  Future<bool> removeBookmark(int postId) async {
    try {
      await delete('bookmarks/$postId');
      debugPrint('🗑️ Post $postId berhasil dihapus dari bookmark.');

      // --- 👇 TAMBAHKAN PUSH KE STREAM 👇 ---
      _streamController.add(BookmarkUpdate(postId: postId, isBookmarked: false));
      // --- 👆 AKHIR TAMBAHAN 👆 ---

      return true;
    } catch (e) {
      debugPrint('❌ Gagal menghapus bookmark untuk post $postId: $e');
      rethrow;
    }
  }

  Future<List<Post>> getBookmarkedPosts() async {
    try {
      final responseData = await get('bookmarks');
      final List<dynamic> postList = responseData is Map<String, dynamic> ? responseData['data'] : responseData;
      final posts = postList.map((json) => Post.fromJson(json)).toList();
      debugPrint('✅ Berhasil mengambil ${posts.length} postingan yang di-bookmark.');
      return posts;
    } catch (e) {
      debugPrint('❌ Gagal mengambil postingan yang di-bookmark: $e');
      rethrow;
    }
  }
}