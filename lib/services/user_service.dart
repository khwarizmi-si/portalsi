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
      final token = await SecureStorage.getToken(); // ✅ Ambil token

      final response = await _client.get(
        Uri.parse('$baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Pakai token
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfileModel.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  //  Get other user's profile by ID or username
  Future<ProfileModel> getOtherProfile(int userId) async {
    try {
      final token = await SecureStorage.getToken(); // ✅ Ambil token

      final response = await _client.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Pakai token
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
      final token = await SecureStorage.getToken(); // ✅ Ambil token

      final response = await _client.post(
        Uri.parse('$baseUrl/account/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Pakai token
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
      final token = await SecureStorage.getToken(); // ✅ Ambil token

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/account/settings'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token', // ✅ Pakai token
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

  void dispose() {
    _client.close();
  }
}
