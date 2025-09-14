// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/websocket_services.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_refresh_service.dart';

class AuthService {
  static const String baseUrl = 'https://api-new.portalsi.com/api';
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();

  // <-- PERUBAHAN: Buat instance WebSocketService yang bisa diakses secara global
  static WebSocketService? _webSocketService;
  static WebSocketService? get webSocketService => _webSocketService;

  // <-- PERUBAHAN: Method ini dihapus karena logikanya sudah pindah ke WebSocketService
  // static Future<void> updateUserActivity() async { ... }

  // <-- PERUBAHAN: Nama method diubah agar lebih jelas
  static Future<void> notifyBackendOnline() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      // Endpoint ini BUKAN untuk koneksi, tapi untuk update status 'is_online' di DB
      await http.post(
        Uri.parse('$baseUrl/websocket/authenticate'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("🔌 Notifikasi ke backend: App Online.");
    } catch (e) {
      print("🔌 Gagal mengirim notifikasi online: $e");
    }
  }

  // <-- PERUBAHAN: Nama method diubah agar lebih jelas
  static Future<void> notifyBackendOffline() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/websocket/disconnect'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("🔌 Notifikasi ke backend: App Offline.");
    } catch (e) {
      print("🔌 Gagal mengirim notifikasi offline: $e");
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'login': email, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        await SecureStorage.saveToken(token);
        await SecureStorage.saveUserId(data['user']['user_id'].toString());
        if (data['refresh_token'] != null) {
          await SecureStorage.saveRefreshToken(data['refresh_token']);
        }

        // <-- PERUBAHAN UTAMA: Inisialisasi WebSocketService di sini
        print("🚀 Menginisialisasi WebSocketService setelah login...");
        _webSocketService = WebSocketService(token: token);
        _webSocketService!.init();

        // Panggil method dengan nama baru
        await AuthService.notifyBackendOnline();

        _tokenRefreshService.start();

        return {
          'success': true,
          'message': 'Login berhasil',
          'token': token,
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
    _tokenRefreshService.stop();

    try {
      // Panggil method dengan nama baru
      await AuthService.notifyBackendOffline();

      // <-- PERUBAHAN: Panggil disconnect dari instance WebSocketService
      _webSocketService?.disconnect();
      _webSocketService = null; // Hapus instance

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
      await SecureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("🧹 Cache dan data sesi telah dibersihkan.");
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
