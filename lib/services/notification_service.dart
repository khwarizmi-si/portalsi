import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class NotificationService {
  final baseUrl = 'https://your-api.com';

  Future<List<dynamic>> getNotifications() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat notifikasi');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    final token = await SecureStorage.getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<bool> markAllAsRead() async {
    final token = await SecureStorage.getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/notifications/read/all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }
}
