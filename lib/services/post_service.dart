// lib/services/post_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'api_service.dart';
import '../models/post_model.dart';

class PostService extends ApiService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  // --- SEMUA KODE CACHE LAMA DIHAPUS DARI SINI ---

  Future<Post?> createPost(Map<String, String> fields, {File? mediaFile}) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
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

  Future<List<dynamic>> fetchPosts({int page = 1}) async {
    final dynamic responseData = await get('posts', queryParams: {
      'page': page.toString(),
    });

    if (responseData is Map<String, dynamic> && responseData['feed'] is List) {
      return responseData['feed'] as List<dynamic>;
    } else if (responseData is Map<String, dynamic> && responseData['data'] is List) {
      return responseData['data'];
    } else if (responseData is List) {
      return responseData;
    } else {
      print(
          '⚠️ Peringatan: Endpoint /posts tidak mengembalikan format list yang diharapkan. Data: $responseData');
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