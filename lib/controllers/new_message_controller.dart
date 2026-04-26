// lib/controllers/new_message_controller.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart'; // Untuk mendapatkan profil user saat ini

class NewMessageController extends ChangeNotifier {
  final FollowService _followService = FollowService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<User> _allFollowers = [];
  List<User> _filteredFollowers = [];
  List<User> get filteredFollowers => _filteredFollowers;

  NewMessageController() {
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    try {
      // 1. Dapatkan dulu profil user yang sedang login untuk mendapatkan ID-nya
      final currentUser = await _profileService.getProfile();
      if (currentUser.id == null) {
        throw Exception("Tidak dapat menemukan ID pengguna saat ini.");
      }

      // 2. Gunakan ID tersebut untuk mengambil daftar followers dari service Anda
      // getFollowers now returns List<User> directly — no need to re-map.
      _allFollowers = await _followService.getFollowers(currentUser.id!);
      _filteredFollowers = _allFollowers;

    } catch (e) {
      _errorMessage = "Gagal memuat daftar followers: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterFollowers(String query) {
    if (query.isEmpty) {
      _filteredFollowers = _allFollowers;
    } else {
      _filteredFollowers = _allFollowers.where((user) {
        final queryLower = query.toLowerCase();
        final usernameLower = user.username.toLowerCase();
        final fullNameLower = (user.fullName ?? '').toLowerCase();
        return usernameLower.contains(queryLower) || fullNameLower.contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }
}