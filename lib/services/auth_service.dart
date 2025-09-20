// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_system_service.dart';
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
  static Future<void> initializeWebSocket(String token) async {
    // Tambahkan async
    if (webSocketService != null && webSocketService?.isConnected == true) {
      debugPrint("✅ WebSocketService sudah diinisialisasi dan terhubung.");
      return;
    }

    debugPrint("🚀 Menginisialisasi WebSocketService...");
    webSocketService = WebSocketService(token: token);
    webSocketService?.connect();

    // Panggil listener global di sini
    await startGlobalListeners();

    // Kirim notifikasi ke backend bahwa aplikasi online
    await notifyBackendOnline(); // Tambahkan await

    // Anda bisa memindahkan start TokenRefreshService ke sini juga agar terpusat
    TokenRefreshService().start();
  }

  // Di dalam class AuthService

// Tambahkan StreamSubscription untuk mengelola listener global
  static StreamSubscription? _globalEventSubscription;

// 👇 TAMBAHKAN METHOD BARU INI
  static Future<void> startGlobalListeners() async {
    final wsService = AuthService.webSocketService;
    final userId = await SecureStorage.getUserId();

    if (wsService == null || userId == null) {
      debugPrint("Gagal memulai listener global: service atau userId tidak ditemukan.");
      return;
    }

    // 1. Tentukan semua channel yang akan didengarkan
    final personalChannel = 'private-user.$userId';
    const announcementsChannel = 'announcements'; // Channel baru untuk pengumuman

    // 2. Subscribe ke semua channel tersebut
    wsService.subscribeToChannel(personalChannel);
    wsService.subscribeToChannel(announcementsChannel);

    // 3. Batalkan listener lama (jika ada) sebelum membuat yang baru
    _globalEventSubscription?.cancel();

    // 4. Dengarkan event stream dari WebSocketService
    _globalEventSubscription = wsService.eventStream.listen((AppEvent appEvent) {
      try {
        final notifData = appEvent.data as Map<String, dynamic>;
        final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

        switch (appEvent.event) {
          case 'user.followed':
            final followerName = notifData['follower_name'] as String? ?? 'Seseorang';
            final followerAvatar = notifData['follower_avatar'] as String?;
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: 'Pengikut Baru',
              body: '$followerName sekarang mengikuti Anda.',
              groupKey: 'follows', // <-- Kunci Grup
              groupChannelId: 'social_channel',
              groupChannelName: 'Interaksi Sosial',
              largeIconUrl: followerAvatar,
            );
            break;

          case 'like.created':
            final userName = notifData['user_name'] as String? ?? 'Seseorang';
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: 'Likes Baru',
              body: '$userName menyukai postingan Anda.',
              groupKey: 'social', // <-- Kunci Grup
              groupChannelId: 'social_channel',
              groupChannelName: 'Interaksi Sosial',
            );
            break;

          case 'comment.created':
            final userName = notifData['user_name'] as String? ?? 'Seseorang';
            final content = notifData['content'] as String? ?? '';
            final commenterAvatarUrl = notifData['user_avatar'] as String?;
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: '$userName berkomentar pada postingan Anda',
              body: content,
              groupKey: 'social', // <-- Kunci Grup (digabung dengan 'like')
              groupChannelId: 'social_channel',
              groupChannelName: 'Interaksi Sosial',
              largeIconUrl: commenterAvatarUrl,
            );
            break;

          case 'announcement.created':
            final announcementTitle = notifData['title'] as String? ?? 'Pengumuman';
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: 'Pengumuman Baru',
              body: announcementTitle,
              groupKey: 'announcements', // <-- Kunci Grup
              groupChannelId: 'announcements_channel',
              groupChannelName: 'Pengumuman',
            );
            break;
        }
      } catch (e, s) {
        debugPrint("❌ Gagal memproses event notifikasi: $e");
        debugPrint("Stack trace: $s");
      }
    });

    print("🎧 Listener global untuk channel '$personalChannel' dan '$announcementsChannel' telah aktif.");
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
