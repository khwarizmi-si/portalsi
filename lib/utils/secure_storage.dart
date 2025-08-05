import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'userId', value: userId);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<int> getUserId() async {
    final storage = FlutterSecureStorage();
    final idString = await storage.read(key: 'userId');
    return int.tryParse(idString ?? '') ?? 0;
  }

  static Future<String?> getUsername() async {
    try {
      return await _storage.read(key: 'username');
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  static Future<void> saveUsername(String username) async {
    try {
      await _storage.write(key: 'username', value: username);
    } catch (e) {
      print('Error saving username: $e');
    }
  }

  static Future<String?> getProfilePicture() async {
    try {
      return await _storage.read(key: 'profile_picture_url');
    } catch (e) {
      print('Error getting profile picture: $e');
      return null;
    }
  }

  static Future<void> saveProfilePicture(String profilePictureUrl) async {
    try {
      await _storage.write(
          key: 'profile_picture_url', value: profilePictureUrl);
    } catch (e) {
      print('Error saving profile picture: $e');
    }
  }

  static Future<String?> getFullName() async {
    try {
      return await _storage.read(key: 'full_name');
    } catch (e) {
      print('Error getting full name: $e');
      return null;
    }
  }

  static Future<void> saveFullName(String fullName) async {
    try {
      await _storage.write(key: 'full_name', value: fullName);
    } catch (e) {
      print('Error saving full name: $e');
    }
  }

  // ✅ Method untuk save semua user data sekaligus
  static Future<void> saveUserProfile({
    required String username,
    String? profilePicture,
    String? fullName,
    required int userId,
  }) async {
    try {
      await Future.wait([
        saveUsername(username),
        saveUserId(userId as String),
        if (profilePicture != null) saveProfilePicture(profilePicture),
        if (fullName != null) saveFullName(fullName),
      ]);
      print('✅ User profile saved successfully');
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  // ✅ Method untuk clear user data saat logout
  static Future<void> clearUserData() async {
    try {
      await Future.wait([
        _storage.delete(key: 'token'),
        _storage.delete(key: 'user_id'),
        _storage.delete(key: 'username'),
        _storage.delete(key: 'profile_picture'),
        _storage.delete(key: 'full_name'),
      ]);
      print('✅ User data cleared');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
