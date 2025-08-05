import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/secure_storage.dart';

class CommentService {
  final baseUrl = 'https://api.portalsi.com/api';

  // Cache untuk mengurangi request berulang
  static final Map<int, List<dynamic>> _cache = {};
  static final Map<int, DateTime> _cacheTime = {};
  static const Duration _cacheExpiration = Duration(minutes: 2);

  Future<List<dynamic>> getComments(int postId) async {
    try {
      // ✅ 1. INSTANT return cache jika ada (tidak peduli expired)
      if (_cache.containsKey(postId)) {
        final cachedTime = _cacheTime[postId];
        final now = DateTime.now();

        if (cachedTime != null &&
            now.difference(cachedTime) < _cacheExpiration) {
          if (kDebugMode) print('📱 Using fresh cache for post $postId');
          return _cache[postId]!;
        } else {
          if (kDebugMode) print('⚠️ Cache expired for post $postId');
          // lanjut fetch baru di bawah
        }
      }

      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // ✅ 2. Request dengan timeout yang lebih pendek
      final res = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 8)); // Timeout lebih cepat

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> comments = [];

        // Parse response dengan cepat
        if (decoded is List) {
          comments = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            comments = decoded['data'];
          } else if (decoded.containsKey('comments') &&
              decoded['comments'] is List) {
            comments = decoded['comments'];
          }
        }

        // ✅ 3. Simpan ke cache
        _cache[postId] = comments;
        _cacheTime[postId] = DateTime.now();

        return comments;
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      // ✅ 4. Jika error, return cache lama jika ada
      if (_cache.containsKey(postId)) {
        print('⚠️ Using stale cache due to error: $e');
        return _cache[postId]!;
      }
      rethrow;
    }
  }

  // ✅ Fire-and-forget add comment (tidak menunggu response)
  Future<bool> sendCommentOptimistic(int postId, String content) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) return false;

      // Kirim request tanpa timeout lama
      final future = http
          .post(
            Uri.parse('$baseUrl/posts/$postId/comments'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'content': content}),
          )
          .timeout(Duration(seconds: 10));

      // ✅ Jangan tunggu response, langsung return true
      // Response akan dihandle di background
      future.then((res) {
        if (res.statusCode == 201 || res.statusCode == 200) {
          print('✅ Comment added successfully');
          // Clear cache agar refresh berikutnya ambil data terbaru
          _cache.remove(postId);
          _cacheTime.remove(postId);
        } else {
          print('❌ Failed to add comment: ${res.statusCode}');
        }
      }).catchError((e) {
        print('❌ Error adding comment: $e');
      });

      return true; // Optimistic return
    } catch (e) {
      print('❌ Exception in addComment: $e');
      return false;
    }
  }

  // ✅ Update cache di background tanpa mengganggu UI
  Future<void> _updateCacheInBackground(int postId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> comments = [];

        if (decoded is List) {
          comments = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            comments = decoded['data'];
          } else if (decoded.containsKey('comments') &&
              decoded['comments'] is List) {
            comments = decoded['comments'];
          }
        }

        // Update cache dengan data terbaru
        _cache[postId] = comments;
        _cacheTime[postId] = DateTime.now();

        print('🔄 Background cache update completed for post $postId');
      }
    } catch (e) {
      print('⚠️ Background cache update failed: $e');
      // Tidak throw error karena ini background operation
    }
  }

  Future<bool> editComment(int commentId, String newContent) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return false;

      final res = await http
          .put(
            Uri.parse('$baseUrl/comments/$commentId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'content': newContent}),
          )
          .timeout(Duration(seconds: 8));

      final success = res.statusCode == 200;

      if (success) {
        // Clear all cache karena comment bisa ada di berbagai post
        _cache.clear();
        _cacheTime.clear();
      }

      return success;
    } catch (e) {
      print('Error editing comment: $e');
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return false;

      final res = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 8));

      final success = res.statusCode == 200 || res.statusCode == 204;

      if (success) {
        // Clear all cache
        _cache.clear();
        _cacheTime.clear();
      }

      return success;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // ✅ Utility untuk clear cache manual
  static void clearCache([int? postId]) {
    if (postId != null) {
      _cache.remove(postId);
      _cacheTime.remove(postId);
    } else {
      _cache.clear();
      _cacheTime.clear();
    }
  }

  // ✅ Utility untuk preload comments (bisa dipanggil dari homepage)
  static Future<void> preloadComments(int postId) async {
    final service = CommentService();
    try {
      await service.getComments(postId);
      print('📱 Preloaded comments for post $postId');
    } catch (e) {
      print('⚠️ Failed to preload comments: $e');
    }
  }
}
