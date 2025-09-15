// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSystemService {
  // Singleton pattern
  NotificationSystemService._internal();
  static final NotificationSystemService instance = NotificationSystemService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Pengaturan inisialisasi untuk Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Gunakan ikon default

    // Pengaturan inisialisasi untuk iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
    print("✅ NotificationService berhasil diinisialisasi.");

    // Buat Channel Notifikasi untuk Android (PENTING!)
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_messages_channel', // id
      'Pesan Baru', // title
      description: 'Channel untuk notifikasi pesan baru.', // description
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print("📢 Android Notification Channel 'Pesan Baru' dibuat.");
  }

  Future<void> showNewMessageNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Detail notifikasi untuk Android, menggunakan channelId yang sudah dibuat
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel',
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Ikon kecil di status bar
    );

    // Detail notifikasi untuk iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
    print("📬 Notifikasi ditampilkan: '$title - $body'");
  }
}