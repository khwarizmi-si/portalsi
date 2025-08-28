// lib/services/user_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Pastikan path ke model User Anda benar

class UserCacheService {
  static const _key = 'userData';

  // Menyimpan data User ke cache
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson()); // Butuh method toJson() di model User
    await prefs.setString(_key, userJson);
  }

  // Mengambil data User dari cache
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_key);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson)); // Butuh factory fromJson() di model User
    }
    return null;
  }

  // Menghapus data User dari cache (berguna saat logout)
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}