import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class StoryService {
  final baseUrl = 'https://your-api.com';

  Future<bool> uploadStory(String mediaUrl) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'media': mediaUrl}),
    );
    return res.statusCode == 201;
  }

  Future<List<dynamic>> getStoryFeed() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/stories/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat story feed');
    }
  }

  Future<bool> deleteStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/stories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<bool> viewStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories/$id/view'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }
}
