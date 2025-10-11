// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart'; // <-- IMPORT BARU
import 'group_service.dart';
import 'notification_system_service.dart';
import 'token_refresh_service.dart';

class AuthService {
  static const String baseUrl = 'https://api-new.portalsi.com/api';
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();

  static WebSocketService? webSocketService;

  static Future<void> initializeWebSocket(String token) async {
    if (webSocketService != null && webSocketService?.isConnected == true) {
      debugPrint("✅ WebSocketService sudah diinisialisasi dan terhubung.");
      return;
    }
    debugPrint("🚀 Menginisialisasi WebSocketService...");
    webSocketService = WebSocketService(token: token);
    webSocketService?.connect();
    await startGlobalListeners();
    await notifyBackendOnline();
    TokenRefreshService().start();
  }

  static StreamSubscription? _globalEventSubscription;

  static Future<void> startGlobalListeners() async {
    final wsService = AuthService.webSocketService;
    final userId = await SecureStorage.getUserId();
    final groupService = GroupService();

    final currentUserId = await SecureStorage.getUserId();

    if (wsService == null || userId == null) {
      debugPrint("Gagal memulai listener global: service atau userId tidak ditemukan.");
      return;
    }

    final personalChannel = 'private-user.$userId';
    const announcementsChannel = 'announcements';
    wsService.subscribeToChannel(personalChannel);
    wsService.subscribeToChannel(announcementsChannel);
    _globalEventSubscription?.cancel();

    _globalEventSubscription = wsService.eventStream.listen((AppEvent appEvent) async {
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
              groupKey: 'follows',
              groupChannelId: 'social_channel',
              groupChannelName: 'Interaksi Sosial',
              largeIconUrl: followerAvatar,
            );
            break;
          case 'like.created':
            final int? likerId = notifData['user_id'] as int?;

            if (likerId != null && likerId == currentUserId) {
              debugPrint("Notifikasi like diabaikan karena dilakukan oleh pengguna sendiri.");
              break;
            }

            final userName = notifData['user_name'] as String? ?? 'Seseorang';
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: 'Likes Baru',
              body: '$userName menyukai postingan Anda.',
              groupKey: 'social',
              groupChannelId: 'social_channel',
              groupChannelName: 'Interaksi Sosial',
            );
            break;
          case 'group.new':
            final messageData = notifData['message'] as Map<String, dynamic>?;
            if (messageData == null) break;

            final sender = messageData['sender'] as Map<String, dynamic>?;
            final content = messageData['content'] as String?;
            final groupId = messageData['group_id'] as int?;

            if (sender != null && content != null && groupId != null) {
              try {
                final groupDetails = await groupService.getGroupDetails(groupId);
                final groupName = groupDetails['name'] as String? ?? 'Grup';
                final groupAvatar = groupDetails['avatar_url'] as String?;
                final senderName = sender['full_name'] as String? ?? 'Seseorang';

                NotificationSystemService.instance.showGroupedNotification(
                  id: id,
                  title: groupName,
                  body: '$senderName: $content',
                  groupKey: 'group_$groupId',
                  groupChannelId: 'group_channel',
                  groupChannelName: 'Pesan Grup',
                  largeIconUrl: groupAvatar,
                );
              } catch (e) {
                debugPrint("Gagal mengambil detail grup untuk notifikasi: $e");
              }
            }
            break;
          case 'comment.created':
            final int? commenterId = notifData['user_id'] as int?;

            if (commenterId != null && commenterId == currentUserId) {
              debugPrint("Notifikasi komentar diabaikan karena dilakukan oleh pengguna sendiri.");
              break;
            }

            final userName = notifData['user_name'] as String? ?? 'Seseorang';
            final content = notifData['content'] as String? ?? '';
            final commenterAvatarUrl = notifData['user_avatar'] as String?;
            NotificationSystemService.instance.showGroupedNotification(
              id: id,
              title: '$userName berkomentar pada postingan Anda',
              body: content,
              groupKey: 'social',
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
              groupKey: 'announcements',
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
        headers: {
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: json.encode({
          'login': email,
          'password': password
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null && user != null) {
          await SecureStorage.saveToken(token);
          await SecureStorage.saveUserId(user['user_id'].toString());
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentUser', json.encode(user));
          await initializeWebSocket(token);
          _tokenRefreshService.start();

          // [PERUBAHAN] Kirim token FCM ke server setelah login berhasil
          await FcmService.instance.sendTokenToServer();

          return {'success': true, 'message': 'Login berhasil', 'user': user};
        }
      }
      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Otentikasi gagal. Silakan login kembali.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/account/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        final errors = responseBody['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.containsKey('current_password')) {
          throw Exception(errors['current_password'][0]);
        }
        throw Exception(responseBody['message'] ?? 'Gagal mengganti password.');
      }
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _tokenRefreshService.stop();
    try {
      // [PERUBAHAN] Hapus token FCM dari server sebelum proses logout lainnya
      await FcmService.instance.deleteTokenFromServer();

      await AuthService.notifyBackendOffline();
      webSocketService?.disconnect();
      webSocketService = null;
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

  Future<Map<String, dynamic>> register(String username, String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'username': username,
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Registrasi berhasil. Silakan cek email untuk verifikasi.'};
      } else if (response.statusCode == 422 && data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        String errorMessage = '';
        errors.forEach((key, value) {
          if (value is List) {
            errorMessage += (value.join('\n') + '\n');
          }
        });
        return {'success': false, 'message': errorMessage.trim(), 'errors': errors};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registrasi gagal. Coba lagi nanti.'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Permintaan melebihi batas waktu. Periksa koneksi Anda.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server: $e'};
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