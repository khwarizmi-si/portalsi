// lib/services/notification_service.dart

import 'dart:convert';

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

  Future<void> showGroupedNotification({
    required int id,                 // ID unik untuk setiap notifikasi anak
    required String title,
    required String body,
    required String groupKey,         // Kunci untuk pengelompokan (cth: 'dm_user_7')
    required String groupChannelId,   // ID Channel (cth: 'direct_messages')
    required String groupChannelName, // Nama Channel (cth: 'Pesan Langsung')
    String? largeIconUrl,         // URL untuk avatar/ikon besar
    String? payload,              // Data untuk dibawa saat notifikasi diklik
  }) async {
    // Unduh avatar jika ada
    final ByteArrayAndroidBitmap? largeIcon = await _getBitmapFromUrl(largeIconUrl);

    // 1. BUAT NOTIFIKASI "ANAK" (Notifikasi Individual)
    final AndroidNotificationDetails childNotificationDetails = AndroidNotificationDetails(
      groupChannelId,
      groupChannelName,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: groupKey, // Tentukan groupKey di sini
      setAsGroupSummary: false, // Ini bukan ringkasan
      largeIcon: largeIcon,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: childNotificationDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    // Tampilkan notifikasi "Anak"
    await _notificationsPlugin.show(id, title, body, notificationDetails, payload: payload);


    // 2. BUAT NOTIFIKASI "INDUK" (Ringkasan Grup)
    // Kita akan menggunakan style Inbox untuk menampilkan ringkasan
    final List<String> lines = [body]; // Nanti bisa diisi dengan riwayat notif

    final AndroidNotificationDetails summaryNotificationDetails = AndroidNotificationDetails(
      groupChannelId,
      groupChannelName,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: groupKey,       // groupKey harus SAMA
      setAsGroupSummary: true,  // INI PENTING: Tandai sebagai ringkasan
      styleInformation: InboxStyleInformation(
          lines,
          contentTitle: title, // Judul ringkasan, misal: "2 Pesan Baru"
          summaryText: groupChannelName // Teks di bawah, misal: "Pesan Langsung"
      ),
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails summaryDetails = NotificationDetails(
      android: summaryNotificationDetails,
      iOS: null, // iOS menangani grouping secara otomatis
    );

    // Tampilkan notifikasi "Induk" dengan ID yang konsisten untuk grup ini
    // Kita bisa menggunakan hashCode dari groupKey sebagai ID unik untuk ringkasan
    await _notificationsPlugin.show(groupKey.hashCode, title, body, summaryDetails);
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
    required int messageId, // Terima messageId
    required String title,
    required String body,
    required DateTime timestamp,
    required Map<String, dynamic> payloadData, // Terima data untuk payload
  }) async {

    final String? profilePictureUrl = payloadData['profile_picture_url'];
    final ByteArrayAndroidBitmap? largeIcon = await _getBitmapFromUrl(profilePictureUrl);

    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel',
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: largeIcon,
      showWhen: true,
      when: timestamp.millisecondsSinceEpoch,
      styleInformation: bigTextStyleInformation,
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

    // [PENTING] Ubah data Map menjadi String JSON untuk payload
    final String payload = jsonEncode(payloadData);

    // [PENTING] Gunakan messageId sebagai ID unik dan tambahkan payload
    await _notificationsPlugin.show(
      messageId, // ID unik per pesan
      title,
      body,
      notificationDetails,
      payload: payload, // Sematkan data sender di sini
    );
    print("📬 Notifikasi ditampilkan dengan ID: $messageId dan payload.");
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

  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Detail notifikasi untuk Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel', // Gunakan channel ID yang sama atau buat baru
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    // Tampilkan notifikasi
    await _notificationsPlugin.show(id, title, body, notificationDetails);
    print("📬 Notifikasi global ditampilkan.");
  }

  Future<void> showRichNotificationWithAvatar({
    required int id,
    required String title,
    required String body,
    String? avatarUrl,
  }) async {
    // Unduh gambar avatar untuk dijadikan ikon besar
    final ByteArrayAndroidBitmap? largeIcon = await _getBitmapFromUrl(avatarUrl);

    // Detail notifikasi untuk Android
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel', // Anda bisa menggunakan channel ID yang sama
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Logo aplikasi Anda (ikon kecil)
      largeIcon: largeIcon,         // Foto profil (ikon besar)
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    // Tampilkan notifikasi
    await _notificationsPlugin.show(id, title, body, notificationDetails);
    print("📬 Notifikasi dengan avatar ditampilkan.");
  }

  Future<void> showCommentNotification({
    required int id,
    required String title,
    required String body,
    String? commenterAvatarUrl, // URL Avatar orang yang komentar
    String? postImageUrl,     // URL Gambar dari postingan
  }) async {
    // 1. Unduh kedua gambar secara paralel
    final Future<ByteArrayAndroidBitmap?> commenterAvatarFuture = _getBitmapFromUrl(commenterAvatarUrl);
    final Future<ByteArrayAndroidBitmap?> postImageFuture = _getBitmapFromUrl(postImageUrl);

    // Tunggu keduanya selesai diunduh
    final ByteArrayAndroidBitmap? commenterAvatar = await commenterAvatarFuture; // Untuk ikon besar
    final ByteArrayAndroidBitmap? postImage = await postImageFuture;           // Untuk gambar utama

    // 2. Buat Style Notifikasi Gambar Besar (BigPicture)
    // Style ini hanya akan muncul saat notifikasi diperluas (expanded)
    final BigPictureStyleInformation? bigPictureStyleInformation = postImage != null
        ? BigPictureStyleInformation(
      postImage,
      largeIcon: commenterAvatar, // Tampilkan avatar juga di mode expanded
      contentTitle: title,
      summaryText: body,
      htmlFormatContentTitle: true,
      htmlFormatSummaryText: true,
    )
        : null;

    // 3. Siapkan detail notifikasi
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_messages_channel',
      'Pesan Baru',
      channelDescription: 'Channel untuk notifikasi pesan baru.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Logo aplikasi (ikon kecil)
      largeIcon: commenterAvatar,     // Avatar komentator (ikon besar)
      styleInformation: bigPictureStyleInformation, // Terapkan style BigPicture
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      // iOS tidak mendukung style ini, akan tampil sebagai notifikasi biasa
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    // 4. Tampilkan Notifikasi
    await _notificationsPlugin.show(id, title, body, notificationDetails);
    print("📬 Notifikasi komentar kaya informasi ditampilkan.");
  }
}