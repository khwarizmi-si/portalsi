import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class FollowService {
  final String _baseUrl = 'https://api.portalsi.com/api';

  Future<String?> _getToken() async {
    return await SecureStorage.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: headers,
      );

      print('Get profile response: ${res.statusCode}');
      print('Get profile body: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Gagal memuat profil: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getMyProfile: $e');
      rethrow;
    }
  }

  // ✅ UPDATED: Support both userId and username
  Future<Map<String, dynamic>> getUserProfile(dynamic userIdentifier) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse(
            '$_baseUrl/profile/$userIdentifier'), // Can be userId or username
        headers: headers,
      );

      print('Get user profile response: ${res.statusCode}');
      print('Get user profile body: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Gagal memuat profil user: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getUserProfile: $e');
      rethrow;
    }
  }

  // ✅ UPDATED: Support username-based follow
  Future<bool> followUser(dynamic userIdentifier) async {
    try {
      final headers = await _getHeaders();
      final url =
          '$_baseUrl/follow/$userIdentifier'; // Can be userId or username

      print('🔄 Attempting to follow user $userIdentifier');
      print('📍 URL: $url');
      print('🔑 Headers: $headers');

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Follow user response code: ${res.statusCode}');
      print('📝 Follow user response body: ${res.body}');
      print('📋 Follow user response headers: ${res.headers}');

      // Check for success status codes
      // 409 with "Sudah di-follow" also means success (already following)
      final success = res.statusCode == 200 ||
          res.statusCode == 201 ||
          (res.statusCode == 409 && res.body.contains('Sudah di-follow'));

      print('✅ Follow success: $success');

      return success;
    } catch (e) {
      print('❌ Error in followUser: $e');
      return false;
    }
  }

  // ✅ UPDATED: Support username-based unfollow
  Future<bool> unfollowUser(dynamic userIdentifier) async {
    try {
      final headers = await _getHeaders();
      final url =
          '$_baseUrl/unfollow/$userIdentifier'; // Can be userId or username

      print('🔄 Attempting to unfollow user $userIdentifier');
      print('📍 URL: $url');
      print('🔑 Headers: $headers');

      final res = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Unfollow user response code: ${res.statusCode}');
      print('📝 Unfollow user response body: ${res.body}');
      print('📋 Unfollow user response headers: ${res.headers}');

      // Check for success status codes (200, 204 for delete)
      // Also handle case where user is not being followed (404 might be success)
      final success = res.statusCode == 200 ||
          res.statusCode == 204 ||
          (res.statusCode == 404 && res.body.contains('tidak ditemukan'));

      print('✅ Unfollow success: $success');

      return success;
    } catch (e) {
      print('❌ Error in unfollowUser: $e');
      return false;
    }
  }

  // ✅ UPDATED: Support both userId and username
  Future<List<dynamic>> getFollowers(dynamic userIdentifier) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/users/$userIdentifier/followers'),
        headers: headers,
      );

      print('Get followers response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['followers'] ?? [];
      } else {
        throw Exception('Gagal mengambil daftar pengikut: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getFollowers: $e');
      rethrow;
    }
  }

  // ✅ UPDATED: Support both userId and username
  Future<List<dynamic>> getFollowing(dynamic userIdentifier) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/users/$userIdentifier/following'),
        headers: headers,
      );

      print('Get following response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('Following data: $data');
        return data['following'] ?? [];
      } else {
        throw Exception(
            'Gagal mengambil daftar yang diikuti: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getFollowing: $e');
      rethrow;
    }
  }

  // ✅ UPDATED: Check follow status using current user's following list
  Future<Map<String, dynamic>> getFollowStatus(String targetUsername) async {
    try {
      print('Checking follow status for target username: $targetUsername');

      // Get current user's profile to get their ID/username
      final myProfile = await getMyProfile();
      final myUserId = myProfile['id'];

      print('My user ID: $myUserId');

      if (myUserId == null) {
        throw Exception('Unable to get current user ID');
      }

      final followingList = await getFollowing(myUserId);
      print('Following list: $followingList');

      // Search for target user in following list
      final followData = followingList.firstWhere(
        (user) {
          final username = user['username']?.toString();
          print('Comparing username $username with $targetUsername');
          return username == targetUsername;
        },
        orElse: () => null,
      );

      print('Follow data found: $followData');

      if (followData != null) {
        final pivot = followData['pivot'] ?? {};
        return {
          'isFollowing': true,
          'status': pivot['status'] ?? 'active',
          'followedAt': pivot['followed_at'],
        };
      }

      return {
        'isFollowing': false,
        'status': null,
        'followedAt': null,
      };
    } catch (e) {
      print('Error getting follow status: $e');
      return {
        'isFollowing': false,
        'status': null,
        'followedAt': null,
      };
    }
  }

  // ✅ UPDATED: Simplified version for username - now calls the updated getFollowStatus
  Future<bool> isFollowing(String targetUsername) async {
    final status = await getFollowStatus(targetUsername);
    return status['isFollowing'] ?? false;
  }

  // ✅ BACKWARD COMPATIBILITY: Keep old method signature for existing code
  Future<Map<String, dynamic>> getFollowStatusLegacy(
      int currentUserId, int targetUserId) async {
    try {
      print(
          'Checking follow status: current=$currentUserId, target=$targetUserId');

      final followingList = await getFollowing(currentUserId);
      print('Following list: $followingList');

      final followData = followingList.firstWhere(
        (user) {
          final userId = user['user_id'];
          print('Comparing $userId with $targetUserId');
          return userId == targetUserId;
        },
        orElse: () => null,
      );

      print('Follow data found: $followData');

      if (followData != null) {
        final pivot = followData['pivot'] ?? {};
        return {
          'isFollowing': true,
          'status': pivot['status'] ?? 'unknown',
          'followedAt': pivot['followed_at'],
        };
      }

      return {
        'isFollowing': false,
        'status': null,
        'followedAt': null,
      };
    } catch (e) {
      print('Error getting follow status: $e');
      return {
        'isFollowing': false,
        'status': null,
        'followedAt': null,
      };
    }
  }

  // ✅ BACKWARD COMPATIBILITY: Simplified version for backward compatibility
  Future<bool> isFollowingLegacy(int currentUserId, int targetUserId) async {
    final status = await getFollowStatusLegacy(currentUserId, targetUserId);
    return status['isFollowing'] ?? false;
  }

  // ✅ NEW: Get follower/following counts for a user
  Future<Map<String, int>> getFollowCounts(dynamic userIdentifier) async {
    try {
      final followers = await getFollowers(userIdentifier);
      final following = await getFollowing(userIdentifier);

      return {
        'followers': followers.length,
        'following': following.length,
      };
    } catch (e) {
      print('Error getting follow counts: $e');
      return {
        'followers': 0,
        'following': 0,
      };
    }
  }

  // Method untuk refresh status setelah follow/unfollow
  Future<void> clearCache() async {
    // Jika Anda menggunakan caching, clear cache di sini
    // Untuk saat ini, method ini kosong tapi bisa digunakan nanti
  }
}
