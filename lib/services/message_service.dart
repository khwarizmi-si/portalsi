import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class MessageService {
  final baseUrl = 'https://your-api.com';

  Future<bool> sendMessage(int receiverId, String content) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiver_id': receiverId, 'message': content}),
    );
    return res.statusCode == 201;
  }

  Future<List<dynamic>> getConversation(int userId) async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil percakapan');
    }
  }

  Future<bool> markAsRead(int messageId) async {
    final token = await SecureStorage.getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/messages/$messageId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }
}
