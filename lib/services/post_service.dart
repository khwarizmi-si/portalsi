// lib/services/post_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // <-- Pastikan import ini ada
import '../models/post_model.dart';

// --- PERBAIKAN: Tambahkan kembali "extends ApiService" ---
class PostService extends ApiService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  // --- KONSTANTA UNTUK CACHING ---
  static const String _cacheKey = 'homeFeedCache';
  static const String _timestampKey = 'homeFeedTimestamp';
  static const int _cacheDurationMinutes = 10;

  // =======================================================================
  // == FUNGSI UNTUK BERANDA DENGAN SISTEM CACHE ==
  // =======================================================================

  Future<List<Post>> getHomeFeedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final cachedTimestamp = prefs.getInt(_timestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        print("✅ Memuat postingan beranda dari CACHE.");
        final List<dynamic> jsonData = jsonDecode(cachedData);
        return jsonData.map((item) => Post.fromJson(item)).toList();
      }
    }

    print("CACHE KADALUARSA/KOSONG. Mengambil postingan beranda dari API...");
    return _fetchAndCacheHomeFeed();
  }

  Future<List<Post>> refreshHomeFeedPosts() async {
    print("🔃 Memaksa refresh postingan beranda dari API...");
    return _fetchAndCacheHomeFeed();
  }

  Future<List<Post>> _fetchAndCacheHomeFeed() async {
    try {
      final List<Post> posts = await fetchPosts(page: 1);
      final List<Map<String, dynamic>> postsAsJson =
      posts.map((post) => post.toJson()).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(postsAsJson));
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      print("📦 Postingan beranda baru disimpan ke cache.");

      return posts;
    } catch (e) {
      print("Error saat mengambil dan caching postingan beranda: $e");
      rethrow;
    }
  }

  Future<void> addPostToCache(Post newPost) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    List<dynamic> cachedPostsJson = [];
    if (cachedData != null) {
      cachedPostsJson = jsonDecode(cachedData);
    }

    cachedPostsJson.insert(0, newPost.toJson());

    await prefs.setString(_cacheKey, jsonEncode(cachedPostsJson));
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    print("➕ Postingan baru ditambahkan ke cache beranda.");
  }

  // =======================================================================
  // == FUNGSI-FUNGSI ANDA YANG SUDAH ADA ==
  // =======================================================================

  Future<Post?> createPost(Map<String, String> fields, {File? mediaFile}) async {
    final token = await getToken(); // Sekarang bisa diakses
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'), // Sekarang bisa diakses
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    if (mediaFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          filename: path.basename(mediaFile.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Post.fromJson(responseData['data'] ?? responseData);
    } else {
      print("Gagal membuat postingan: ${response.body}");
      return null;
    }
  }

  Future<Post?> fetchPinnedPost() async {
    // Implementasi placeholder Anda dipertahankan
    return null;
  }

  Future<List<Post>> fetchPosts({int page = 1}) async {
    final dynamic responseData = await get('posts', queryParams: {
      'page': page.toString(),
    });

    if (responseData is Map<String, dynamic> && responseData['data'] is List) {
      final List<dynamic> postsData = responseData['data'];
      return postsData.map((item) => Post.fromJson(item)).toList();
    } else if (responseData is List) {
      return responseData.map((item) => Post.fromJson(item)).toList();
    } else {
      print(
          '⚠️ Peringatan: Endpoint /posts dengan paginasi tidak mengembalikan format yang diharapkan. Data: $responseData');
      return [];
    }
  }

  Future<List<Post>> fetchExplorePosts(
      {String? tag, String sort = 'random'}) async {
    final queryParams = <String, String>{'sort': sort};
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }
    final dynamic data = await get('explore', queryParams: queryParams);
    if (data is List) {
      return data.map((item) => Post.fromJson(item)).toList();
    }
    if (data is Map<String, dynamic> && data['posts'] is List) {
      return (data['posts'] as List).map((item) => Post.fromJson(item)).toList();
    }
    print("⚠️ Unexpected /explore response format: $data");
    return [];
  }

  Future<Post> getPostDetail(int id) async {
    final dynamic data = await get('posts/$id');
    if (data is Map<String, dynamic>) {
      return Post.fromJson(data);
    } else {
      throw Exception('Format data untuk post #$id tidak valid.');
    }
  }

  Future<bool> deletePost(int id) async {
    await delete('posts/$id');
    return true;
  }
}