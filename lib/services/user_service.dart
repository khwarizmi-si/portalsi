// services/profile_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/secure_storage.dart';

// Pindahkan ProfileModel ke file model terpisah (misal: 'models/profile_model.dart')
// untuk menjaga kebersihan struktur.
// Namun, jika ingin tetap di sini, pastikan kelas ini di atas ProfileService.
class ProfileModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String bio;
  final String profilePictureUrl;
  final bool isVerified;

  ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.profilePictureUrl,
    this.isVerified = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      bio: json['bio'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  factory ProfileModel.fromAuthData(Map<String, dynamic> authData) {
    final userData = authData['user'] ?? {};
    return ProfileModel(
      id: userData['user_id'] ?? 0,
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      fullName: userData['full_name'] ?? '',
      bio: userData['bio'] ?? '',
      profilePictureUrl: userData['profile_picture_url'] ?? '',
      isVerified: userData['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
    };
  }

  ProfileModel copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profilePictureUrl,
    bool? isVerified,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class ProfileService {
  static const String _baseUrl = 'https://api.portalsi.com/api';
  final http.Client _client = http.Client();

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ProfileModel> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/account/settings'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

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

  Future<ProfileModel> getOtherProfile(String username) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile/$username'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfileModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ??
            'Failed to load profile: ${response.statusCode}';
        throw Exception(errorMessage);
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
      throw Exception('Error fetching other profile: $e');
    }
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl/account/settings'),
        headers: headers,
        body: json.encode(profile.toJson()),
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

  Future<ProfileModel?> getCurrentUserForComments() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      final response = await _client.get(
        Uri.parse('$_baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final profile = ProfileModel.fromJson(data);
        await _saveUserDataToStorage(profile);
        return profile;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserDataToStorage(ProfileModel profile) async {
    await Future.wait([
      SecureStorage.saveUsername(profile.username),
      SecureStorage.saveProfilePicture(profile.profilePictureUrl),
      SecureStorage.saveFullName(profile.fullName),
    ]);
  }

  void dispose() {
    _client.close();
  }
}
