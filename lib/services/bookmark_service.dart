// lib/services/bookmark_service.dart
import 'api_service.dart';
import '../models/post_model.dart';

class BookmarkService extends ApiService {
  // Singleton Pattern
  BookmarkService._internal();
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;

  /// Menambahkan post ke bookmark
  Future<bool> addBookmark(int postId) async {
    try {
      // Endpoint: POST /bookmarks/{postId}
      await post('bookmarks/$postId');
      print('✅ Post $postId berhasil ditambahkan ke bookmark.');
      return true;
    } catch (e) {
      print('❌ Gagal menambahkan bookmark untuk post $postId: $e');
      rethrow; // Lempar kembali error agar bisa ditangani di controller
    }
  }

  /// Menghapus post dari bookmark
  Future<bool> removeBookmark(int postId) async {
    try {
      // Endpoint: DELETE /bookmarks/{postId}
      await delete('bookmarks/$postId');
      print('🗑️ Post $postId berhasil dihapus dari bookmark.');
      return true;
    } catch (e) {
      print('❌ Gagal menghapus bookmark untuk post $postId: $e');
      rethrow;
    }
  }
  Future<List<Post>> getBookmarkedPosts() async {
    try {
      // Endpoint: GET /bookmarks
      final responseData = await get('bookmarks');

      // API mungkin mengembalikan data dalam format { "data": [...] } atau langsung [...]
      final List<dynamic> postList = responseData is Map<String, dynamic> ? responseData['data'] : responseData;

      final posts = postList.map((json) => Post.fromJson(json)).toList();
      print('✅ Berhasil mengambil ${posts.length} postingan yang di-bookmark.');
      return posts;
    } catch (e) {
      print('❌ Gagal mengambil postingan yang di-bookmark: $e');
      rethrow;
    }
  }
}