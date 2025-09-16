// lib/services/announcement_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portal_si/models/announcement_model.dart';
import 'package:portal_si/services/api_service.dart';
import 'dart:typed_data'; // WAJIB: Untuk menangani data gambar sebagai 'bytes' (Uint8List) di web.
import 'package:flutter/foundation.dart' show kIsWeb; // WAJIB: Untuk mendeteksi platform web (kIsWeb).
import 'package:http/http.dart' as http; // WAJIB: Untuk melakukan request HTTP (MultipartRequest).
import 'package:image_picker/image_picker.dart'; // WAJIB: Untuk bisa mengenali tipe data XFile.
import '../utils/secure_storage.dart';

class AnnouncementService extends ApiService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  // --- Konstanta untuk Caching ---
  static const String _cacheKey = 'pinnedAnnouncementsCache';
  static const String _timestampKey = 'pinnedAnnouncementsTimestamp';
  static const int _cacheDurationMinutes = 10;

  /// Mengambil pengumuman yang di-pin, memprioritaskan cache jika valid.
  Future<List<Announcement>> getPinnedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final cachedTimestamp = prefs.getInt(_timestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        print("✅ Memuat Pinned Announcements dari CACHE.");
        final List<dynamic> jsonData = jsonDecode(cachedData);
        return jsonData.map((item) => Announcement.fromJson(item)).toList();
      }
    }
    print("⚠️ CACHE Pinned Announcements KOSONG/KADALUARSA. Mengambil dari API...");
    return _fetchAndCachePinnedAnnouncements();
  }

  /// Memaksa pengambilan data baru dari API dan memperbarui cache.
  Future<List<Announcement>> refreshPinnedAnnouncements() async {
    print("🔃 Memaksa refresh Pinned Announcements dari API...");
    return _fetchAndCachePinnedAnnouncements();
  }

  /// Fungsi internal untuk fetch dari API dan simpan ke cache.
  Future<List<Announcement>> _fetchAndCachePinnedAnnouncements() async {
    const String endpoint = 'announcements/pinned';
    try {
      final response = await get(endpoint) as List<dynamic>;
      final announcements = response.map((json) => Announcement.fromJson(json as Map<String, dynamic>)).toList();

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> announcementsAsJson =
      announcements.map((ann) => ann.toJson()).toList();

      await prefs.setString(_cacheKey, jsonEncode(announcementsAsJson));
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      print("📦 Pinned Announcements baru disimpan ke cache.");

      return announcements;
    } catch (e) {
      rethrow;
    }
  }

  /// Mengambil daftar semua pengumuman (tidak di-cache).
  Future<List<Announcement>> getAnnouncements() async {
    const String endpoint = 'announcements';
    try {
      final response = await get(endpoint) as List<dynamic>;
      final announcements = response.map((json) => Announcement.fromJson(json as Map<String, dynamic>)).toList();
      return announcements;
    } catch (e) {
      rethrow;
    }
  }

  /// Mengirim data pengumuman baru ke server.
  Future<void> createAnnouncement({
    required String title,
    required String content,
    required bool isPinned,
    XFile? image, // <-- PERBAIKAN: Ubah tipe parameter menjadi XFile?
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api-new.portalsi.com/api/announcements'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['is_pinned'] = isPinned ? '1' : '0';

    if (image != null) {
      if (kIsWeb) {
        Uint8List imageBytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: image.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: image.name,
        ));
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal membuat pengumuman. Status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- ✨ FUNGSI BARU UNTUK MENGHAPUS PENGUMUMAN ---
  /// Menghapus pengumuman berdasarkan ID.
  Future<void> deleteAnnouncement(int announcementId) async {
    final String endpoint = 'announcements/$announcementId';
    try {
      // Asumsi `ApiService` Anda memiliki method `delete` yang menangani DELETE request.
      // Jika tidak, Anda perlu membuatnya.
      await delete(endpoint);
      print("📢 Pengumuman dengan ID $announcementId berhasil dihapus dari server.");
    } catch (e) {
      print("❌ Gagal menghapus pengumuman dengan ID $announcementId: $e");
      // Melempar kembali error agar bisa ditangani di UI
      rethrow;
    }
  }
}