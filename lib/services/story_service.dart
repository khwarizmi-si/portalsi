import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/story_model.dart'; // <-- 1. IMPORT MODEL
import '../utils/secure_storage.dart';

class StoryService {
  final baseUrl = 'https://api-new.portalsi.com/api';

  // --- 👇 FUNGSI BARU DITAMBAHKAN DI SINI 👇 ---
  /// Mengambil data story lengkap dari satu pengguna berdasarkan ID.
  ///

  Future<bool> viewStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories/$id/view'), // <-- Endpoint yang sesuai
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<UserWithStories> getStoriesForUser(int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/stories/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      // --- 2. TAMBAHKAN LOG UNTUK RESPON SUKSES ---
      log('✅ SUCCESS: Respons API untuk getStoriesForUser (userId: $userId)');
      log('Status Code: ${res.statusCode}');
      // Mencetak body respons mentah ke console
      log(res.body);
      // ---------------------------------------------

      return UserWithStories.fromJson(jsonDecode(res.body));
    } else {
      // --- 3. TAMBAHKAN LOG UNTUK RESPON GAGAL ---
      log('❌ FAILED: Gagal memuat story (userId: $userId)');
      log('Status Code: ${res.statusCode}');
      log('Response Body: ${res.body}');
      // --------------------------------------------

      throw Exception('Gagal memuat story untuk pengguna ID: $userId');
    }
  }


  Future<bool> uploadStory(String mediaUrl) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'media_url': mediaUrl}),
    );
    return res.statusCode == 201;
  }

  Future<bool> deleteStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/stories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getStoryFeed() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/stories/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      print("berhasil ngambil story lagi");
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat story feed');
    }
  }
}