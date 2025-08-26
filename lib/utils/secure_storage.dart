// lib/utils/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  // --- Kunci untuk menyimpan data (dibuat konsisten) ---
  static const _keyToken = 'authToken';
  static const _keyRefreshToken = 'refreshToken'; // <-- Kunci baru
  static const _keyUserId = 'userId';
  static const _keyUsername = 'username';
  static const _keyFullName = 'fullName';
  static const _keyProfilePicture = 'profilePictureUrl';

  // --- Metode untuk Token Akses ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
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

  // --- ✨ METODE BARU UNTUK REFRESH TOKEN ---
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
  }
  // -----------------------------------------

  // --- Metode untuk User ID ---
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<int?> getUserId() async {
    final idString = await _storage.read(key: _keyUserId);
    return int.tryParse(idString ?? '');
  }

  // --- Metode untuk Info Profil Lainnya ---
  static Future<void> saveUsername(String username) async => await _storage.write(key: _keyUsername, value: username);
  static Future<String?> getUsername() async => await _storage.read(key: _keyUsername);

  static Future<void> saveFullName(String fullName) async => await _storage.write(key: _keyFullName, value: fullName);
  static Future<String?> getFullName() async => await _storage.read(key: _keyFullName);

  static Future<void> saveProfilePicture(String url) async => await _storage.write(key: _keyProfilePicture, value: url);
  static Future<String?> getProfilePicture() async => await _storage.read(key: _keyProfilePicture);

  // --- ✅ Method untuk save semua user data sekaligus (diperbaiki) ---
  static Future<void> saveUserProfile({
    required String username,
    String? profilePicture,
    String? fullName,
    required int userId,
  }) async {
    await saveUsername(username);
    await saveUserId(userId.toString()); // Konversi int ke String
    if (profilePicture != null) await saveProfilePicture(profilePicture);
    if (fullName != null) await saveFullName(fullName);
    print('✅ User profile saved successfully');
  }

  // --- ✅ Method untuk clear semua data saat logout (diperbaiki) ---
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      print('🗑️ Semua data aman telah dihapus.');
    } catch (e) {
      print('Error saat menghapus semua data aman: $e');
    }
  }
}