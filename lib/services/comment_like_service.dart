// lib/services/comment_like_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class CommentLikeService {
  static const String baseUrl = 'https://api.portalsi.com/api';

  /// Toggle like status untuk comment
  /// Endpoint: POST/DELETE https://api.portalsi.com/api/comments/{comment_id}/like
  Future<bool> toggleCommentLike(int commentId) async {
    try {
      final authToken = await SecureStorage.getToken();

      if (authToken == null) {
        print('No auth token found');
        return false;
      }

      // Cek apakah user sudah like comment ini
      final isLiked = await isCommentLikedByUser(commentId);

      // Jika sudah like, maka unlike (DELETE)
      // Jika belum like, maka like (POST)
      final response = isLiked
          ? await http
                .delete(
                  Uri.parse('$baseUrl/comments/$commentId/like'),
                  headers: {
                    'Authorization': 'Bearer $authToken',
                    'Accept': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 10))
          : await http
                .post(
                  Uri.parse('$baseUrl/comments/$commentId/like'),
                  headers: {
                    'Authorization': 'Bearer $authToken',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 10));

      print('Comment like toggle - Method: ${isLiked ? "DELETE" : "POST"}');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print('Comment like toggled successfully');
        return true;
      } else {
        print('Failed to toggle comment like: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  /// Get likes untuk specific comment
  /// Endpoint: GET https://api.portalsi.com/api/comments/{comment_id}/likes
  Future<List<dynamic>> getCommentLikes(int commentId) async {
    try {
      final authToken = await SecureStorage.getToken();

      if (authToken == null) {
        print('No auth token found');
        return [];
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/comments/$commentId/likes'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('GET /comments/$commentId/likes');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        if (data is List) {
          return data;
        } else if (data is Map && data['data'] != null) {
          return data['data'];
        } else if (data is Map && data['likes'] != null) {
          return data['likes'];
        }

        return [];
      } else {
        print('Failed to get comment likes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting comment likes: $e');
      return [];
    }
  }

  /// Check if current user liked a comment
  Future<bool> isCommentLikedByUser(int commentId) async {
    try {
      final likes = await getCommentLikes(commentId);
      final currentUserId = await SecureStorage.getUserId();

      return likes.any(
        (like) => like['user_id'].toString() == currentUserId.toString(),
      );
    } catch (e) {
      print('Error checking comment like status: $e');
      return false;
    }
  }

  /// Get comment likes count
  Future<int> getCommentLikesCount(int commentId) async {
    try {
      final likes = await getCommentLikes(commentId);
      return likes.length;
    } catch (e) {
      print('Error getting comment likes count: $e');
      return 0;
    }
  }
}
