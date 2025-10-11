// services/user_service.dart (SUDAH DIPERBAIKI)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:portal_si/models/user_model.dart';
import '../utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// --- IMPORT TAMBAHAN YANG DIBUTUHKAN ---
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
// Catatan: import 'dart:io' tidak lagi dibutuhkan untuk fungsi upload & pick.
import 'dart:io';


class ProfileService {
  static const String _baseUrl = 'https://api-new.portalsi.com/api';
  final http.Client _client = http.Client();

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // --- Konstanta untuk Caching Profil ---
  static const String _profileCacheKey = 'userProfileCache';
  static const String _profileTimestampKey = 'userProfileTimestamp';
  static const int _cacheDurationMinutes = 10;

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Authentication required');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Tidak ada perubahan pada fungsi-fungsi di bawah ini ---
  Future<User> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_profileCacheKey);
    final cachedTimestamp = prefs.getInt(_profileTimestampKey);

    if (cachedData != null && cachedTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      if (DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes) {
        print("✅ Memuat profil dari CACHE.");
        return User.fromJson(jsonDecode(cachedData));
      }
    }
    print("CACHE PROFIL KADALUARSA. Mengambil dari API...");
    return _fetchAndCacheProfile();
  }

  Future<User> refreshProfile() async {
    print("🔃 Memaksa refresh profil dari API...");
    return _fetchAndCacheProfile();
  }

  Future<User> _fetchAndCacheProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(Uri.parse('$_baseUrl/user'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final user = User.fromJson(responseData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileCacheKey, jsonEncode(user.toJson()));
        await prefs.setInt(_profileTimestampKey, DateTime.now().millisecondsSinceEpoch);
        print("📦 Profil baru disimpan ke cache.");
        _preCacheProfileMedia(user);
        return user;
      } else {
        throw Exception('Gagal memuat profil dari API: Status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _preCacheProfileMedia(User user) {
    final cacheManager = DefaultCacheManager();
    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
      print("Pre-caching gambar profil...");
      cacheManager.downloadFile(user.profilePictureUrl!);
    }
    for (var post in user.recentPosts) {
      if (post.mediaUrl.isNotEmpty) {
        print("Pre-caching media post ID: ${post.postId}...");
        cacheManager.downloadFile(post.mediaUrl);
      }
    }
  }

  Future<List<dynamic>> fetchSuggestions() async {
    try {
      // Menggunakan _getHeaders() untuk mendapatkan token secara otomatis
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$_baseUrl/suggestions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // Pastikan ada key 'users' dan merupakan sebuah List
        if (data['users'] is List) {
          return data['users'] as List<dynamic>;
        } else {
          // Jika format tidak sesuai, kembalikan list kosong
          return [];
        }
      } else {
        // Jika request gagal, lempar error
        throw Exception('Gagal memuat saran profil. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error di fetchSuggestions: $e");
      rethrow; // Lempar kembali error untuk ditangani oleh FutureBuilder
    }
  }

  Future<bool> updateProfile(User user, {XFile? profilePicture, XFile? banner}) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Authentication required');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/account/settings'),
      );

      // 1. Tambahkan Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // 2. Tambahkan field-field teks dari model User
      // API Anda mengharapkan `full_name`, bukan `fullName`
      request.fields['username'] = user.username;
      if (user.fullName != null) request.fields['full_name'] = user.fullName!;
      if (user.email != null) request.fields['email'] = user.email!;
      if (user.bio != null) request.fields['bio'] = user.bio!;
      request.fields['is_private'] = user.isPrivate ? '1' : '0';


      // 3. Tambahkan file foto profil jika ada yang baru
      if (profilePicture != null) {
        if (kIsWeb) {
          Uint8List fileBytes = await profilePicture.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'profile_picture', // Sesuaikan dengan nama field di API
            fileBytes,
            filename: profilePicture.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'profile_picture', // Sesuaikan dengan nama field di API
            profilePicture.path,
            filename: profilePicture.name,
          ));
        }
      }

      // 4. Tambahkan file banner jika ada yang baru
      if (banner != null) {
        if (kIsWeb) {
          Uint8List fileBytes = await banner.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'banner', // Sesuaikan dengan nama field di API
            fileBytes,
            filename: banner.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'banner', // Sesuaikan dengan nama field di API
            banner.path,
            filename: banner.name,
          ));
        }
      }

      // 5. Kirim request dan proses response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await refreshProfile(); // Refresh cache setelah berhasil update
        return true;
      } else {
        print("Gagal update profil. Status: ${response.statusCode}");
        print("Body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error di updateProfile service: $e");
      rethrow;
    }
  }

  Future<User> getOtherProfile(String username) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(Uri.parse('$_baseUrl/profile/$username'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load profile for $username');
      }
    } catch (e) {
      throw Exception('Error fetching other profile: $e');
    }
  }
  // --- Akhir dari bagian yang tidak berubah ---


  // =======================================================================
  // ❗❗ PERUBAHAN UTAMA ADA DI DUA FUNGSI DI BAWAH INI ❗❗
  // =======================================================================

  /// [DIPERBAIKI] Memilih gambar dari galeri atau kamera.
  /// Mengembalikan XFile agar bisa diproses lebih lanjut untuk web/mobile.
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      // Langsung kembalikan XFile tanpa mengubahnya ke File
      return image;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }
}