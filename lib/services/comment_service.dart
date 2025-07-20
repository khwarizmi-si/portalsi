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
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
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
