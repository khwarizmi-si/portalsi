// lib/services/user_service.dart
import 'api_service.dart';

class AvatarService extends ApiService {
  // Singleton pattern untuk memastikan hanya ada satu instance dari service ini
  AvatarService._internal();
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;

  /// Mengambil informasi avatar untuk seorang user dari endpoint baru.
  ///
  /// Mengembalikan sebuah Map yang berisi:
  /// - 'profile_picture_url'
  /// - 'has_story'
  /// - 'story_viewed'
  Future<Map<String, dynamic>> getCircleAvatarInfo(int userId) async {
    try {
      final data = await get('circle-avatar/$userId');
      // Endpoint Anda mengembalikan data di dalam key 'circle_avatar', jadi kita akses itu
      if (data != null && data['circle_avatar'] is Map<String, dynamic>) {
        return data['circle_avatar'] as Map<String, dynamic>;
      }
      throw Exception('Format data avatar tidak valid');
    } catch (e) {
      print('Error fetching circle avatar info for user $userId: $e');
      // Mengembalikan nilai default jika terjadi error agar UI tidak crash
      return {
        'profile_picture_url': null,
        'has_story': false,
        'story_viewed': false,
      };
    }
  }
}