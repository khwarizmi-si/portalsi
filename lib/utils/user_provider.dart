import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // PERBAIKAN: Nama getter diubah menjadi 'currentUser' (konvensi Dart)
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Memuat data pengguna dari cache SharedPreferences.
  Future<void> fetchCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userString = prefs.getString('currentUser');

      if (userString != null) {
        final Map<String, dynamic> userMap = json.decode(userString);
        _currentUser = User.fromJson(userMap);
        print("✅ Data pengguna berhasil dimuat dari SharedPreferences.");
        notifyListeners();
      } else {
        print("⚠️ Tidak ada data pengguna di SharedPreferences.");
      }
    } catch (e) {
      print("🚨 Gagal memuat data pengguna: $e");
      _currentUser = null;
      notifyListeners();
    }
  }

  // --- 👇 METHOD BARU DITAMBAHKAN DI SINI 👇 ---
  /// Memperbarui state currentUser dan menyimpannya kembali ke cache.
  Future<void> updateCurrentUser(User updatedUser) async {
    try {
      _currentUser = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      // Ubah objek User menjadi Map, lalu menjadi String JSON untuk disimpan
      final String userString = json.encode(updatedUser.toJson());
      await prefs.setString('currentUser', userString);

      print("💾 Data pengguna berhasil diperbarui dan disimpan ke SharedPreferences.");

      // Beri tahu semua listener bahwa data telah berubah
      notifyListeners();
    } catch (e) {
      print("🚨 Gagal menyimpan pembaruan data pengguna: $e");
    }
  }
}