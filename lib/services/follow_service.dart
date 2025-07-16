import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';
import 'dart:convert';

class FollowService {
  final baseUrl = 'https://your-api.com';

  Future<bool> followUser(int userId) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/follow/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<bool> unfollowUser(int userId) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/unfollow/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getFollowers(int userId) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/users/$userId/followers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil followers');
    }
  }

  Future<List<dynamic>> getFollowing(int userId) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/users/$userId/following'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil following');
    }
  }
}
