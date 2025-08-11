// lib/services/like_service.dart
import 'api_service.dart';
import '../models/like_model.dart';

class LikeService extends ApiService {
  // Singleton Pattern
  LikeService._internal();
  static final LikeService _instance = LikeService._internal();
  factory LikeService() => _instance;

  /// Toggle like/unlike pada sebuah post.
  Future<bool> toggleLike(int postId) async {
    await post('posts/$postId/like');
    return true;
  }

  /// Mengambil semua user yang menyukai sebuah post.
  Future<List<Like>> getLikes(int postId) async {
    final List<dynamic> data = await get('posts/$postId/likes');
    return data.map((item) => Like.fromJson(item)).toList();
  }

  /// Mengambil HANYA jumlah like (jika API mendukung).
  Future<int> getLikeCount(int postId) async {
    final data = await get('posts/$postId/likes/count');
    if (data is Map<String, dynamic> && data.containsKey('count')) {
      return data['count'];
    }
    return 0;
  }

  /// Mengecek apakah user saat ini sudah me-like (jika API mendukung).
  Future<bool> isLikedByCurrentUser(int postId) async {
    final data = await get('posts/$postId/likes/status');
    if (data is Map<String, dynamic> && data.containsKey('is_liked')) {
      return data['is_liked'];
    }
    return false;
  }
}
