// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_refresh_service.dart'; // <-- 1. Import service baru

class AuthService {
  static const String baseUrl = 'https://api-new.portalsi.com/api';
  // 2. Inisialisasi TokenRefreshService
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();


  static Future<void> updateUserActivity() async {
    // Fungsi ini hanya perlu memanggil metode updateActivity
    // yang sudah ada di WebSocketService Anda.
    await webSocketService.updateActivity();
  }

  static Future<void> authenticateWebSocket() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/websocket/authenticate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("🔌 Autentikasi WebSocket berhasil (App Online).");
      } else {
        print("🔌 Gagal melakukan autentikasi WebSocket: ${response.body}");
      }
    } catch (e) {
      print("🔌 Terjadi error saat autentikasi WebSocket: $e");
    }
  }

  // [MODIFIKASI] Tambahkan 'static'
  static Future<void> disconnectWebSocket() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/websocket/disconnect'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        print("🔌 Diskoneksi WebSocket berhasil (App Offline).");
      } else {
        print("🔌 Gagal melakukan diskoneksi WebSocket: ${response.body}");
      }
    } catch (e) {
      print("🔌 Terjadi error saat diskoneksi WebSocket: $e");
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login'),
        body: {'login': email, 'password': password},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Simpan token akses dan refresh token (jika ada)
        await SecureStorage.saveToken(data['token']);
        await SecureStorage.saveUserId(data['user']['user_id'].toString());

        // Asumsi API login mengembalikan 'refresh_token'
        if (data['refresh_token'] != null) {
          await SecureStorage.saveRefreshToken(data['refresh_token']);
        }

        await AuthService.authenticateWebSocket();
        // --- 👇 PERUBAHAN UTAMA: Mulai timer refresh token ---
        _tokenRefreshService.start();

        return {
          'success': true,
          'message': 'Login berhasil',
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        final data = json.decode(response.body);
        String message = 'Login gagal';

        if (data is Map<String, dynamic>) {
          final errors = data.map(
                (key, value) => MapEntry(
              key,
              (value is List && value.isNotEmpty) ? value.first : '',
            ),
          );
          final allErrors = errors.values.where((e) => e != '').toList();
          if (allErrors.isNotEmpty) message = allErrors.first;
        }

        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  Future<Map<String, dynamic>> register(
      String username,
      String fullName,
      String email,
      String password,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {
        'username': username,
        'full_name': fullName,
        'email': email,
        'password': password,
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'errors': data};
    }
  }

  Future<void> logout() async {
    _tokenRefreshService.stop(); // Hentikan timer refresh token

    try {
      // [MODIFIKASI] Panggil diskoneksi WebSocket sebelum menghapus token
      await AuthService.disconnectWebSocket();

      final token = await SecureStorage.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      print("Gagal logout dari server, token akan dihapus secara lokal: $e");
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("🧹 Cache (postingan, profil, dll.) telah dibersihkan.");

      await SecureStorage.deleteAll();
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}