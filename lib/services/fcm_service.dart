// lib/services/fcm_service.dart

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/notification_system_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import '../firebase_options.dart'; // File ini akan dibuat otomatis oleh FlutterFire CLI

// Handler untuk notifikasi saat aplikasi di background/terminated
// HARUS berada di level atas (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🔔 Menangani notifikasi background: ${message.messageId}");

  // Di sini Anda bisa memproses data notifikasi dan menampilkannya
  // menggunakan NotificationSystemService Anda yang sudah ada.
  _handleNotificationPayload(message);
}

// Fungsi helper untuk memproses payload notifikasi
void _handleNotificationPayload(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;

  if (notification == null) return;

  final title = notification.title ?? 'Notifikasi Baru';
  final body = notification.body ?? '';
  // ID unik untuk setiap notifikasi agar tidak menimpa satu sama lain
  final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  // Gunakan data kustom ('type') dari backend untuk menentukan jenis notifikasi
  final notificationType = data['type'] as String?;
  final largeIconUrl = data['largeIconUrl'] as String?;
  final groupKey = data['groupKey'] as String?;

  switch (notificationType) {
    case 'dm':
      NotificationSystemService.instance.showGroupedNotification(
        id: id,
        title: title,
        body: body,
        groupKey: groupKey ?? 'dms',
        groupChannelId: 'dm_channel',
        groupChannelName: 'Pesan Langsung',
        largeIconUrl: largeIconUrl,
      );
      break;
    case 'social':
      NotificationSystemService.instance.showGroupedNotification(
        id: id,
        title: title,
        body: body,
        groupKey: groupKey ?? 'social',
        groupChannelId: 'social_channel',
        groupChannelName: 'Interaksi Sosial',
        largeIconUrl: largeIconUrl,
      );
      break;
    default:
      NotificationSystemService.instance.showSimpleNotification(
        id: id,
        title: title,
        body: body,
      );
  }
}

class FcmService {
  FcmService._internal();
  static final FcmService instance = FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Minta izin notifikasi dari pengguna (iOS & Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Izin notifikasi FCM diberikan.');
        // Setup listener
        _setupListeners();
        // Dapatkan dan kirim token FCM awal
        sendTokenToServer();
      } else {
        debugPrint('❌ Pengguna menolak izin notifikasi FCM.');
      }
    } catch (e) {
      debugPrint("🔥 Gagal menginisialisasi FCM: $e");
    }
  }

  void _setupListeners() {
    // Listener untuk notifikasi saat aplikasi di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Menerima notifikasi foreground: ${message.notification?.title}');
      _handleNotificationPayload(message);
    });

    // Handler ketika pengguna mengklik notifikasi (saat aplikasi di background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notifikasi diklik, membuka aplikasi...');
      // Anda bisa menambahkan logika navigasi di sini berdasarkan message.data
    });
  }

  Future<void> sendTokenToServer() async {
    try {
      String? token = await _fcm.getToken();
      if (token == null) {
        debugPrint("❌ Gagal mendapatkan token FCM.");
        return;
      }
      debugPrint("📱 Token FCM: $token");

      final apiToken = await SecureStorage.getToken();
      if (apiToken == null) return; // Pengguna belum login

      // Ganti dengan endpoint backend Anda
      const String endpoint = 'https://api.portalsi.com/api/device-tokens';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Token FCM berhasil dikirim ke server.");
      } else {
        debugPrint("❌ Gagal mengirim token FCM ke server (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Error saat mengirim token FCM: $e");
    }
  }

  Future<void> deleteTokenFromServer() async {
    try {
      String? fcmToken = await _fcm.getToken();
      if (fcmToken == null) return;

      final apiToken = await SecureStorage.getToken();
      if (apiToken == null) return;

      // Ganti dengan endpoint backend Anda
      const String endpoint = 'https://api.portalsi.com/api/device-tokens';
      await http.delete(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'token': fcmToken}),
      );
      debugPrint("✅ Token FCM dihapus dari server.");
    } catch (e) {
      debugPrint("🔥 Gagal menghapus token FCM dari server: $e");
    }
  }
}