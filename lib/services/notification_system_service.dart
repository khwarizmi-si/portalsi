// lib/services/notification_service.dart

import 'package:http/http.dart' as http;
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
    String? profilePictureUrl, // URL untuk foto profil
    required DateTime timestamp,     // Waktu pesan dikirim
  }) async {

    // [BARU] Helper untuk mengunduh gambar dan mengubahnya menjadi format notifikasi
    final ByteArrayAndroidBitmap? largeIcon = await _getBitmapFromUrl(profilePictureUrl);

    // [BARU] Style untuk menampilkan teks yang panjang saat notifikasi diperluas
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    // [MODIFIKASI] Detail notifikasi Android sekarang lebih kaya
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel',
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Logo aplikasi Anda (ikon kecil)
      largeIcon: largeIcon,         // Foto profil (ikon besar)
      showWhen: true,               // Tampilkan timestamp
      when: timestamp.millisecondsSinceEpoch, // Gunakan waktu dari server
      styleInformation: bigTextStyleInformation, // Terapkan style teks panjang
    );

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
    print("📬 Notifikasi kaya informasi ditampilkan.");
  }

  /// [BARU] Fungsi privat untuk mengunduh gambar dari URL.
  Future<ByteArrayAndroidBitmap?> _getBitmapFromUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      print("Gagal mengunduh gambar untuk notifikasi: $e");
    }
    return null;
  }
}