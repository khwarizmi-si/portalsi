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
}
