// lib/controllers/create_group_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';

class CreateGroupController extends ChangeNotifier {
  final FollowService _followService = FollowService();
  final ProfileService _profileService = ProfileService();
  final GroupService _groupService = GroupService();

  bool isLoading = true;
  String? errorMessage;
  List<User> _allFollowers = [];
  List<User> filteredFollowers = [];

  final Set<User> _selectedUsers = {};
  Set<User> get selectedUsers => _selectedUsers;

  final TextEditingController groupNameController = TextEditingController();
  File? avatarFile;
  File? coverFile; // [TAMBAHAN] State untuk file cover
  bool isCreatingGroup = false;

  CreateGroupController() {
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    // ... (kode ini tetap sama)
    try {
      final currentUser = await _profileService.getProfile();
      if (currentUser.id == null) throw Exception("ID user tidak ditemukan");
      final followersData = await _followService.getFollowers(currentUser.id!);
      _allFollowers = followersData.map((data) => User.fromJson(data)).toList();
      filteredFollowers = _allFollowers;
    } catch (e) {
      errorMessage = "Gagal memuat followers: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleUserSelection(User user) {
    // ... (kode ini tetap sama)
    if (_selectedUsers.contains(user)) {
      _selectedUsers.remove(user);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  void filterFollowers(String query) {
    // ... (kode ini tetap sama)
    if (query.isEmpty) {
      filteredFollowers = _allFollowers;
    } else {
      filteredFollowers = _allFollowers.where((user) {
        final queryLower = query.toLowerCase();
        return user.username.toLowerCase().contains(queryLower) ||
            (user.fullName ?? '').toLowerCase().contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      if (isAvatar) {
        avatarFile = File(pickedFile.path);
      } else {
        coverFile = File(pickedFile.path); // [TAMBAHAN] Logika untuk memilih cover
      }
      notifyListeners();
    }
  }

  // [PERUBAHAN] Fungsi ini sekarang mengembalikan Map, bukan boolean
  Future<Map<String, dynamic>?> createGroup() async {
    if (groupNameController.text.isEmpty) {
      return null;
    }

    isCreatingGroup = true;
    notifyListeners();

    final newGroup = await _groupService.createGroup(
      name: groupNameController.text,
      avatar: avatarFile,
      cover: coverFile, // [TAMBAHAN] Mengirim file cover
    );

    isCreatingGroup = false;
    notifyListeners();
    return newGroup;
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }
}