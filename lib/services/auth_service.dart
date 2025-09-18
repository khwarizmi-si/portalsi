// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_refresh_service.dart';

class AuthService {
  static const String baseUrl = 'https://api-new.portalsi.com/api';
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();

  // =======================================================================
  // [PERUBAIKAN UTAMA] Bagian WebSocket dibuat statis
  // =======================================================================

  /// **Variabel statis untuk menyimpan satu instance WebSocketService untuk seluruh aplikasi.**
  static WebSocketService? webSocketService;

  /// **Metode statis yang dicari oleh SplashScreen untuk inisialisasi.**
  /// Metode ini akan dipanggil saat aplikasi pertama kali dibuka (jika sesi masih aktif).
  static Future<void> initializeWebSocket(String token) {

    if (webSocketService != null && webSocketService?.isConnected == true) {
      debugPrint("✅ WebSocketService sudah diinisialisasi dan terhubung.");
      return Future.value(); // Kembalikan Future yang sudah selesai
    }

    debugPrint("🚀 Menginisialisasi WebSocketService dari startup...");
    webSocketService = WebSocketService(token: token);

    // Kirim notifikasi online ke backend
    notifyBackendOnline();

    // Pastikan webSocketService tidak null sebelum memanggil connect
    // dan kembalikan Future-nya agar bisa di-await
    if (webSocketService != null) {
      return webSocketService!.connect(); // <-- KEMBALIKAN Future dari connect()
    } else {
      return Future.error("Gagal membuat instance WebSocketService.");
    }

  }

  // =======================================================================

  /// Notifikasi ke backend bahwa pengguna sekarang online.
  static Future<void> notifyBackendOnline() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/websocket/authenticate'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint("🔌 Notifikasi ke backend: App Online.");
    } catch (e) {
      debugPrint("🔌 Gagal mengirim notifikasi online: $e");
    }
  }

  /// Notifikasi ke backend bahwa pengguna akan offline.
  static Future<void> notifyBackendOffline() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/websocket/disconnect'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint("🔌 Notifikasi ke backend: App Offline.");
    } catch (e) {
      debugPrint("🔌 Gagal mengirim notifikasi offline: $e");
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

        // Simpan semua data sesi
        await SecureStorage.saveToken(token);
        await SecureStorage.saveUserId(data['user']['user_id'].toString());
        if (data['refresh_token'] != null) {
          await SecureStorage.saveRefreshToken(data['refresh_token']);
        }

        // [PENTING] Panggil metode inisialisasi statis setelah login berhasil.
        initializeWebSocket(token);

        _tokenRefreshService.start();

        return {
          'success': true,
          'message': 'Login berhasil',
          'user': data['user'],
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  Future<void> logout() async {
    _tokenRefreshService.stop();

    try {
      // Kirim notifikasi offline ke backend
      await AuthService.notifyBackendOffline();

      // Putuskan koneksi WebSocket
      webSocketService?.disconnect();
      webSocketService = null; // Hapus instance dari memori

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
      // Hapus semua data sesi dari perangkat
      await SecureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("🧹 Cache dan data sesi telah dibersihkan.");
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
