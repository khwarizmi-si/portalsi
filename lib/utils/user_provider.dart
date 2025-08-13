// lib/providers/user_provider.dart (contoh nama file)

import 'package:flutter/foundation.dart';
import '../models/user_model.dart'; // <-- Cukup import User model
import '../services/user_service.dart'; // <-- Panggil UserService yang sudah benar

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // --- PERBAIKAN DI SINI ---
  // Getter sekarang mengembalikan tipe data yang benar (User?)
  User? get currentUser => _currentUser;
  // -------------------------

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Panggil UserService, bukan ProfileService
      final userService = ProfileService();
      _currentUser = await userService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
