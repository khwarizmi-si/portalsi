// lib/controllers/create_group_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
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
  bool _isCreatingGroup = false;

  // Web-compatible image storage (bytes + filename)
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  Uint8List? _coverBytes;
  String? _coverFileName;

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
  // Legacy File getters — always null on web, kept for API compat
  get avatarFile => null;
  get coverFile => null;
  // Bytes getters for display
  Uint8List? get avatarBytes => _avatarBytes;
  Uint8List? get coverBytes => _coverBytes;
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
      _mutuals = userListJson.map(_toUser).toList();
      _hasNextPage = response['next_page_url'] != null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Safely converts a dynamic item to User — handles both raw Map and
  /// already-deserialized User objects.
  User _toUser(dynamic item) {
    if (item is User) return item;
    return User.fromJson(item as Map<String, dynamic>);
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
      _mutuals.addAll(userListJson.map(_toUser).toList());
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
    try {
      Uint8List? bytes;
      String? fileName;

      if (kIsWeb) {
        // Web: use file_picker to get raw bytes
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          bytes = result.files.first.bytes;
          fileName = result.files.first.name;
        }
      } else {
        // Native: use image_picker, then read bytes
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1080,
        );
        if (pickedFile != null) {
          bytes = await pickedFile.readAsBytes();
          fileName = pickedFile.name;
        }
      }

      if (bytes != null) {
        if (isAvatar) {
          _avatarBytes = bytes;
          _avatarFileName = fileName ?? 'avatar.jpg';
        } else {
          _coverBytes = bytes;
          _coverFileName = fileName ?? 'cover.jpg';
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
      final uri = Uri.parse('https://api.portalsi.com/api/groups');
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      request.fields['name'] = groupNameController.text.trim();

      final memberIds = _selectedUsers.map((user) => user.id.toString()).toList();
      for (int i = 0; i < memberIds.length; i++) {
        request.fields['members[$i]'] = memberIds[i];
      }

      if (_avatarBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'avatar',
          _avatarBytes!,
          filename: _avatarFileName ?? 'avatar.jpg',
        ));
      }
      if (_coverBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'cover',
          _coverBytes!,
          filename: _coverFileName ?? 'cover.jpg',
        ));
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