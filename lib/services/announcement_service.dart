// lib/services/announcement_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portal_si/models/announcement_model.dart';
import 'package:portal_si/services/api_service.dart';

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
  Future<Map<String, dynamic>> createAnnouncement({
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
    final Map<String, File>? files = image != null ? {'image': image} : null;
    try {
      final response = await postMultipart(endpoint, body: body, files: files);
      return response as Map<String, dynamic>;
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