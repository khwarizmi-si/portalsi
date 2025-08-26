// lib/utils/user_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mengambil data profil pengguna yang saat ini login dari server.
  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    _error = null;
    // Notify listeners di awal untuk menunjukkan status loading
    notifyListeners();

    try {
      // Di kode Anda, Anda memanggil ProfileService.
      // Pastikan nama kelas di user_service.dart sesuai.
      final userService = ProfileService();
      _currentUser = await userService.getProfile();
    } catch (e) {
      _error = "Gagal memuat data pengguna: ${e.toString()}";
      print(_error);
    } finally {
      _isLoading = false;
      // Notify listeners di akhir untuk update UI dengan data atau pesan error
      notifyListeners();
    }
  }
}