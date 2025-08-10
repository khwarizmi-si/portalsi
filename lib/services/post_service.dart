import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/secure_storage.dart';

class PostService {
  final baseUrl = 'https://api.portalsi.com/api';

  Future<List<dynamic>> fetchAllPosts() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/posts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat postingan');
    }
  }

  Future<List<dynamic>> fetchExplorePosts(
      {String? tag, String sort = 'random'}) async {
    final token = await SecureStorage.getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final queryParams = <String, String>{
      'sort': sort,
    };

    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }

    final uri = Uri.https('api.portalsi.com', '/api/explore', queryParams);

    try {
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // 🛡️ Tambahkan pengecekan tipe di sini:
        if (data is Map<String, dynamic> && data.containsKey('posts')) {
          return data['posts'];
        } else if (data is List) {
          return data;
        } else {
          throw Exception('Unexpected response format: $data');
        }
      } else {
        print('Error fetching explore posts: ${res.statusCode} - ${res.body}');
        throw Exception('Failed to load explore posts');
      }
    } catch (e) {
      print('Exception in fetchExplorePosts: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPostDetail(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<bool> createPost(Map<String, dynamic> data) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  }

  Future<bool> updatePost(int id, Map<String, dynamic> data) async {
    final token = await SecureStorage.getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  Future<bool> deletePost(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getExplorePosts() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/explore'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat postingan eksplorasi');
    }
  }
}
