import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';
import 'dart:convert';

class LikeService {
  final baseUrl = 'https://your-api.com';

  Future<bool> toggleLike(int postId) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getLikes(int postId) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/posts/$postId/likes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil data likes');
    }
  }
}
