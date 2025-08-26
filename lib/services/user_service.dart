// services/user_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:portal_si/models/user_model.dart';
import '../utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

  /// Mengambil profil pengguna, memprioritaskan cache jika valid.
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

  /// Memaksa pengambilan data profil baru dari API dan memperbarui cache.
  Future<User> refreshProfile() async {
    print("🔃 Memaksa refresh profil dari API...");
    return _fetchAndCacheProfile();
  }

  /// Fungsi internal untuk fetch dari API dan simpan ke cache.
  Future<User> _fetchAndCacheProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(Uri.parse('$_baseUrl/user'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final user = User.fromJson(responseData);

        // Simpan data dan timestamp baru ke cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileCacheKey, jsonEncode(user.toJson()));
        await prefs.setInt(_profileTimestampKey, DateTime.now().millisecondsSinceEpoch);
        print("📦 Profil baru disimpan ke cache.");

        // Memulai pre-caching media di latar belakang
        _preCacheProfileMedia(user);

        return user;
      } else {
        throw Exception('Gagal memuat profil dari API: Status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mengunduh dan menyimpan media ke cache di latar belakang.
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

  /// Memperbarui profil pengguna di server dan otomatis merefresh cache.
  Future<bool> updateProfile(User user) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl/account/settings'),
        headers: headers,
        body: json.encode(user.toJson()),
      );
      if (response.statusCode == 200) {
        await refreshProfile();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Mengambil profil pengguna lain berdasarkan username (tidak di-cache).
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

  /// Mengunggah gambar profil baru ke server.
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/account/settings'),
      );

      request.headers.addAll({'Authorization': 'Bearer $token'});
      request.files.add(
          await http.MultipartFile.fromPath('profile_picture', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await refreshProfile();
        final Map<String, dynamic> data = json.decode(response.body);
        return data['profile_picture_url'];
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to upload image: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Memilih gambar dari galeri atau kamera.
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }
}