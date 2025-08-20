// services/profile_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:portal_si/models/user_model.dart'; // <-- Cukup import User model
import '../utils/secure_storage.dart';

// [DIHAPUS] Class ProfileModel sudah tidak diperlukan lagi
// karena semua fungsionalitasnya sudah diwakili oleh User model.

class ProfileService {
  static const String _baseUrl = 'https://api.portalsi.com/api';
  final http.Client _client = http.Client();

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Authentication required');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<User> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response =
          await _client.get(Uri.parse('$_baseUrl/user'), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Ambil bagian "data" kalau API ada bungkusannya
        final userJson = responseData['data'] ?? responseData;

        return User.fromJson(userJson);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  // [DIUBAH] Mengembalikan Future<User>
  Future<User> getOtherProfile(String username) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(Uri.parse('$_baseUrl/profile/$username'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data); // Parse sebagai User
      } else {
        // ... (error handling lainnya tetap sama)
        throw Exception('Failed to load profile for $username');
      }
    } catch (e) {
      throw Exception('Error fetching other profile: $e');
    }
  }

  Future<bool> updateProfile(User user) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl/account/settings'),
        headers: headers,
        body: json.encode(user.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

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
        final Map<String, dynamic> data = json.decode(response.body);
        return data['profile_picture_url'];
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ??
            'Failed to upload image: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

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

  // [DIUBAH] Mengembalikan Future<User?>
  Future<User?> getCurrentUserForComments() async {
    try {
      final user =
          await getProfile(); // Panggil saja getProfile() yang sudah ada
      await _saveUserDataToStorage(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  // [DIUBAH] Menerima objek User
  Future<void> _saveUserDataToStorage(User user) async {
    await Future.wait([
      SecureStorage.saveUsername(user.username),
      if (user.profilePictureUrl != null)
        SecureStorage.saveProfilePicture(user.profilePictureUrl!),
      if (user.fullName != null) SecureStorage.saveFullName(user.fullName!),
    ]);
  }

  void dispose() {
    _client.close();
  }
}
