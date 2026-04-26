import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class NotificationService {
  final baseUrl = 'https://api-new.portalsi.com/api';

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      if (res.body.isEmpty) return [];

      final data = jsonDecode(res.body);

      // Case 1: bare array  →  [{...}, {...}]
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }

      // Case 2: Laravel pagination / wrapped  →  {"data": [...], ...}
      if (data is Map<String, dynamic>) {
        final inner = data['data'] ?? data['notifications'] ?? data['items'];
        if (inner is List) {
          return List<Map<String, dynamic>>.from(inner);
        }
        // Single-level with a 'notifications' array at root
        for (final key in data.keys) {
          if (data[key] is List) {
            debugPrint('⚠️ NotificationService: using "$key" key from response');
            return List<Map<String, dynamic>>.from(data[key] as List);
          }
        }
      }

      debugPrint('⚠️ NotificationService: unexpected format — ${res.body.substring(0, 200)}');
      return [];
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
