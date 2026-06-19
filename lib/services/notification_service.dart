import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoint.dart';
import '../utils/secure_storage.dart';

class NotificationService {
  final baseUrl = ApiEndpoints.apiUrl;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      if (res.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(res.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Format data notifikasi tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat notifikasi (${res.statusCode})');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    final token = await SecureStorage.getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  Future<bool> markAllAsRead() async {
    final token = await SecureStorage.getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/notifications/read/all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
