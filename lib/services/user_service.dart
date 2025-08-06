import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/secure_storage.dart';

class ProfileModel {
  final String username;
  final String email;
  final String fullName;
  final String bio;
  final String profilePictureUrl;

  ProfileModel({
    required this.username,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.profilePictureUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      bio: json['bio'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
    );
  }

  // Add this method to handle auth data format
  factory ProfileModel.fromAuthData(Map<String, dynamic> authData) {
    // Extract user data from auth response structure
    final userData = authData['user'] ?? {};

    return ProfileModel(
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      fullName: userData['full_name'] ?? '',
      bio: userData['bio'] ?? '',
      profilePictureUrl: userData['profile_picture_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
    };
  }

  ProfileModel copyWith({
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profilePictureUrl,
  }) {
    return ProfileModel(
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}

class ProfileService {
  static const String baseUrl = 'https://api.portalsi.com/api';
  final http.Client _client = http.Client();

  // Get current profile data
  Future<ProfileModel> getProfile() async {
    try {
      // 1. Dapatkan token
      final token = await SecureStorage.getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      // 2. Buat request ke endpoint profile settings (untuk current user)
      final response = await _client.get(
        Uri.parse('$baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // 3. Handle response
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ProfileModel.fromJson(responseData);
      } else {
        final errorMsg = responseData['message'] ??
            'Failed to load profile (Status: ${response.statusCode})';
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again');
    } on http.ClientException {
      throw Exception('Server connection failed');
    } on FormatException {
      throw Exception('Invalid server response');
    } catch (e) {
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  // ✅ UPDATED: Get other user's profile by USERNAME instead of ID
  Future<ProfileModel> getOtherProfile(String username) async {
    try {
      final token = await SecureStorage.getToken();

      final response = await _client.get(
        Uri.parse('$baseUrl/profile/$username'), // ✅ Use username in URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Other profile status: ${response.statusCode}');
      print('Other profile body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfileModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching other profile: $e');
    }
  }

  // Update profile data
  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final token = await SecureStorage.getToken();

      final response = await _client.post(
        Uri.parse('$baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profile.toJson()),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final token = await SecureStorage.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/account/settings'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        // Jangan set 'Content-Type' manual, biarkan MultipartRequest yang atur
      });

      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload status: ${response.statusCode}');
      print('Upload body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['profile_picture_url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  // Pick image from gallery or camera
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

  Future<Map<String, dynamic>?> getCurrentUserForComments() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      final response = await _client.get(
        Uri.parse('$baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 8));

      print(
          '👤 Get current user for comments - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract user info yang dibutuhkan comment section
        final userInfo = {
          'username': data['username'] ?? '',
          'profile_picture_url': data['profile_picture_url'] ?? '',
          'full_name': data['full_name'] ?? '',
          'email': data['email'] ?? '',
        };

        // ✅ Save ke storage untuk cache
        await _saveUserDataToStorage(userInfo);

        return userInfo;
      } else {
        print('❌ Failed to get current user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting current user for comments: $e');
      return null;
    }
  }

  // ✅ Helper method untuk save ke storage
  Future<void> _saveUserDataToStorage(Map<String, dynamic> userInfo) async {
    try {
      await Future.wait([
        SecureStorage.saveUsername(userInfo['username'] ?? ''),
        SecureStorage.saveProfilePicture(userInfo['profile_picture_url'] ?? ''),
        if (userInfo['full_name'] != null)
          SecureStorage.saveFullName(userInfo['full_name']),
      ]);
      print('✅ User data cached to storage');
    } catch (e) {
      print('⚠️ Failed to cache user data: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
