import 'dart:async';

import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';
import 'dart:convert';
import 'dart:io';

class LikeService {
  final String baseUrl = 'https://api.portalsi.com/api';

  // Timeout duration for HTTP requests
  static const Duration _timeout = Duration(seconds: 10);

  /// Toggle like/unlike for a specific post
  Future<bool> toggleLike(int postId) async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/$postId/like'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      // Handle different success status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage =
            responseBody['message'] ?? 'Unknown error occurred';
        throw Exception('Failed to toggle like: $errorMessage');
      }
    } on SocketException {
      throw Exception(
        'Network connection failed. Please check your internet connection.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get all likes for a specific post
  Future<List<dynamic>> getLikes(int postId) async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/posts/$postId/likes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Handle different response formats
        if (responseBody is List) {
          return responseBody;
        } else if (responseBody is Map<String, dynamic>) {
          // If response is wrapped in a 'data' field
          if (responseBody.containsKey('data')) {
            final data = responseBody['data'];
            if (data is List) {
              return data;
            }
          }
          // If response has 'likes' field
          if (responseBody.containsKey('likes')) {
            final likes = responseBody['likes'];
            if (likes is List) {
              return likes;
            }
          }
          // Return empty list if structure is unexpected
          return [];
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          final errorMessage =
              responseBody['message'] ?? 'Unknown error occurred';
          throw Exception(
            'Failed to get likes: $errorMessage (Status: ${response.statusCode})',
          );
        } catch (e) {
          throw Exception(
            'Failed to get likes. Status code: ${response.statusCode}',
          );
        }
      }
    } on SocketException {
      throw Exception(
        'Network connection failed. Please check your internet connection.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from server: $e');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get like count for a specific post (optimized endpoint)
  Future<int> getLikeCount(int postId) async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/posts/$postId/likes/count'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody is Map<String, dynamic>) {
          return responseBody['count'] ?? 0;
        }
        return 0;
      } else {
        // Fallback to getting all likes and counting
        final likes = await getLikes(postId);
        return likes.length;
      }
    } catch (e) {
      // Fallback to getting all likes and counting
      try {
        final likes = await getLikes(postId);
        return likes.length;
      } catch (e) {
        return 0;
      }
    }
  }

  /// Check if current user has liked a specific post
  Future<bool> isLikedByCurrentUser(int postId) async {
    try {
      final token = await SecureStorage.getToken();
      final currentUserId = await SecureStorage.getUserId();

      if (token == null || token.isEmpty) {
        return false;
      }

      // Try optimized endpoint first
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/posts/$postId/likes/status'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          return responseBody['is_liked'] ?? false;
        }
      } catch (e) {
        // Fallback to getting all likes
      }

      // Fallback: get all likes and check
      final likes = await getLikes(postId);
      return likes.any((like) => like['user_id'] == currentUserId);
    } catch (e) {
      return false;
    }
  }

  /// Batch get likes data for multiple posts (if API supports it)
  Future<Map<int, Map<String, dynamic>>> getBatchLikesData(
    List<int> postIds,
  ) async {
    Map<int, Map<String, dynamic>> result = {};

    try {
      final token = await SecureStorage.getToken();
      final currentUserId = await SecureStorage.getUserId();

      if (token == null || token.isEmpty) {
        return result;
      }

      // Try batch endpoint first
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/posts/likes/batch'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'post_ids': postIds}),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic>) {
            // Convert string keys to int keys
            responseBody.forEach((key, value) {
              final postId = int.tryParse(key);
              if (postId != null && value is Map<String, dynamic>) {
                result[postId] = value;
              }
            });
            return result;
          }
        }
      } catch (e) {
        // Fallback to individual requests
      }

      // Fallback: get likes for each post individually
      for (final postId in postIds) {
        try {
          final likes = await getLikes(postId);
          result[postId] = {
            'count': likes.length,
            'is_liked': likes.any((like) => like['user_id'] == currentUserId),
            'likes': likes,
          };
        } catch (e) {
          result[postId] = {'count': 0, 'is_liked': false, 'likes': []};
        }
      }
    } catch (e) {
      // Return empty result on error
    }

    return result;
  }
}
