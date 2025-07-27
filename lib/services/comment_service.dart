import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/secure_storage.dart';

class CommentService {
  final baseUrl = 'https://api.portalsi.com/api';

  Future<List<dynamic>> getComments(int postId) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('GET /posts/$postId/comments');
    print('Status code: ${res.statusCode}');
    print('Response body: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      // Ubah sesuai key 'data' atau lainnya
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      } else {
        throw Exception('Format response tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat komentar');
    }
  }

  Future<bool> addComment(int postId, String content) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );
    return res.statusCode == 201;
  }

  Future<bool> editComment(int commentId, String newContent) async {
    final token = await SecureStorage.getToken();
    final res = await http.put(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': newContent}),
    );
    return res.statusCode == 200;
  }

  Future<bool> deleteComment(int commentId) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }
}
