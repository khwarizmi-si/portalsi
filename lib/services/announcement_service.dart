import 'dart:convert';
import 'dart:io';

import 'api_service.dart'; // Mengimpor kelas dasar ApiService

/// Service untuk mengelola semua interaksi terkait data pengumuman dengan API.
///
/// Service ini menggunakan pola Singleton untuk memastikan hanya ada satu instance
/// yang digunakan di seluruh aplikasi. Ia mewarisi (extends) `ApiService` untuk
/// mendapatkan fungsionalitas request HTTP yang sudah terstandardisasi.
class AnnouncementService extends ApiService {
  // Implementasi Singleton Pattern
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  /// Mengambil daftar semua pengumuman dari server.
  /// Sesuai dengan: GET /api/announcements
  Future<List<dynamic>> getAnnouncements() async {
    const String endpoint = 'announcements';
    try {
      final response = await get(endpoint);
      // API mengembalikan list, jadi kita cast hasilnya.
      // Sebaiknya dibuatkan model class (misal: Announcement.fromJson) untuk parsing yang lebih aman.
      return response as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Mengirim data pengumuman baru ke server.
  /// Sesuai dengan: POST /api/announcements
  ///
  /// [title] Judul pengumuman.
  /// [content] Isi atau deskripsi pengumuman.
  /// [isPinned] Status apakah pengumuman disematkan. API mengharapkan '1' (true) atau '0' (false).
  /// [image] File gambar opsional.
  /// [pollData] Daftar opsi polling dalam bentuk List of String.
  // Lokasi: lib/services/announcement_service.dart

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required bool isPinned,
    File? image,
    List<String>? pollData,
  }) async {
    const String endpoint = 'announcements';

    final Map<String, String> body = {
      'title': title,
      'content': content,
      'pinned': isPinned ? '1' : '0',
    };

    // if (pollData != null && pollData.isNotEmpty) {
    //   body['poll_data'] = jsonEncode(pollData);
    // }

    final Map<String, File>? files = image != null ? {'image': image} : null;

    try {
      // 1. Tangkap hasil dari pemanggilan API ke dalam sebuah variabel
      final response = await postMultipart(endpoint, body: body, files: files);

      // 2. Cetak respons tersebut ke konsol
      print('✅ Respons API Sukses (Create Announcement): $response');

    } catch (e) {
      // 3. (Opsional) Cetak juga jika terjadi error
      print('❌ Error API (Create Announcement): $e');
      rethrow;
    }
  }

  /// Memperbarui data pengumuman yang ada di server.
  /// Sesuai dengan: POST /api/announcements/{id}
  ///
  /// [announcementId] ID dari pengumuman yang akan diubah.
  /// [title], [content], dll. adalah data baru yang opsional. Hanya data yang diisi yang akan dikirim.
  Future<void> updateAnnouncement({
    required String announcementId,
    String? title,
    String? content,
    bool? isPinned,
    File? image,
    List<String>? pollData,
  }) async {
    // Endpoint dinamis berdasarkan ID pengumuman.
    final String endpoint = 'announcements/$announcementId';
    final Map<String, String> body = {};

    // Tambahkan data ke body hanya jika nilainya tidak null.
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (isPinned != null) body['pinned'] = isPinned ? '1' : '0';
    if (pollData != null) body['poll_data'] = jsonEncode(pollData);

    final Map<String, File>? files = image != null ? {'image': image} : null;

    try {
      // API ini menggunakan POST untuk update, sesuai dokumentasi.
      await postMultipart(endpoint, body: body, files: files);
    } catch (e) {
      rethrow;
    }
  }

  /// Menghapus pengumuman dari server.
  /// Sesuai dengan: DELETE /api/announcements/{id}
  ///
  /// [announcementId] ID dari pengumuman yang akan dihapus.
  Future<void> deleteAnnouncement({required String announcementId}) async {
    final String endpoint = 'announcements/$announcementId'; //
    try {
      await delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }
}