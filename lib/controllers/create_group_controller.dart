// lib/controllers/create_group_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../utils/secure_storage.dart';

class CreateGroupController with ChangeNotifier {
  final GroupService _groupService = GroupService();
  final TextEditingController groupNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<User> _mutuals = [];
  final List<User> _selectedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  File? _avatarFile;
  File? _coverFile;
  bool _isCreatingGroup = false;

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  String _currentQuery = '';
  Timer? _debounce;

  // Getters
  List<User> get mutuals => _mutuals;
  List<User> get selectedUsers => _selectedUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get avatarFile => _avatarFile;
  File? get coverFile => _coverFile;
  bool get isCreatingGroup => _isCreatingGroup;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNextPage => _hasNextPage;

  CreateGroupController() {
    _fetchInitialData();
    groupNameController.addListener(notifyListeners);
    scrollController.addListener(_onScroll);
    addListener(_proactiveLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    groupNameController.dispose();
    scrollController.dispose();
    removeListener(_proactiveLoadMore);
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      fetchMoreData();
    }
  }

  void _proactiveLoadMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading &&
          !_isLoadingMore &&
          _hasNextPage &&
          scrollController.position.hasContentDimensions &&
          scrollController.position.maxScrollExtent == 0.0) {
        fetchMoreData();
      }
    });
  }

  Future<void> _fetchInitialData() async {
    _isLoading = true;
    _currentPage = 1;
    _hasNextPage = true;
    _mutuals.clear();
    notifyListeners();

    try {
      Map<String, dynamic> response;
      if (_currentQuery.trim().isEmpty) {
        response = await _groupService.getMutuals(page: 1);
      } else {
        response = await _groupService.searchUsers(page: 1, query: _currentQuery);
      }

      final List<dynamic> userListJson = response['data'] ?? [];
      _mutuals = userListJson.map((json) => User.fromJson(json)).toList();
      _hasNextPage = response['next_page_url'] != null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreData() async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    try {
      Map<String, dynamic> response;
      if (_currentQuery.trim().isEmpty) {
        response = await _groupService.getMutuals(page: _currentPage);
      } else {
        response = await _groupService.searchUsers(page: _currentPage, query: _currentQuery);
      }

      final List<dynamic> userListJson = response['data'] ?? [];
      _mutuals.addAll(userListJson.map((json) => User.fromJson(json)).toList());
      _hasNextPage = response['next_page_url'] != null;
    } catch (e) {
      _currentPage--;
      debugPrint("Gagal memuat halaman selanjutnya: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();
      if (_currentQuery != trimmedQuery) {
        _currentQuery = trimmedQuery;
        _fetchInitialData();
      }
    });
  }

  void toggleUserSelection(User user) {
    if (_selectedUsers.any((selected) => selected.id == user.id)) {
      _selectedUsers.removeWhere((selected) => selected.id == user.id);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  Future<void> pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        if (isAvatar) {
          _avatarFile = File(pickedFile.path);
        } else {
          _coverFile = File(pickedFile.path);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  Future<Map<String, dynamic>?> createGroup() async {
    if (groupNameController.text.trim().isEmpty) {
      _errorMessage = "Nama grup tidak boleh kosong.";
      notifyListeners();
      return null;
    }
    _isCreatingGroup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await SecureStorage.getToken();
      final uri = Uri.parse('https://api-new.portalsi.com/api/groups');
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      request.fields['name'] = groupNameController.text.trim();

      final memberIds = _selectedUsers.map((user) => user.id.toString()).toList();
      for (int i = 0; i < memberIds.length; i++) {
        request.fields['members[$i]'] = memberIds[i];
      }

      if (_avatarFile != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', _avatarFile!.path));
      }
      if (_coverFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cover', _coverFile!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['data'] as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Gagal membuat grup.';
        return null;
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan: $e";
      return null;
    } finally {
      _isCreatingGroup = false;
      notifyListeners();
    }
  }
}