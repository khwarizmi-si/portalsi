// lib/controllers/feed_controller.dart

import 'package:portal_si/config/api_endpoint.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/pages/post_detail_page.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../utils/navigation_helper.dart';
import '../utils/secure_storage.dart';
import '../widgets/feed/filter_dialog.dart';
import '../helper/time_helper.dart'; // <-- Pastikan import ini ada

class FeedController extends ChangeNotifier {
  final BuildContext context;
  final TickerProvider vsync;

  // State variables
  List<Post> posts = [];
  List<User> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool showSearchResults = false;
  // Variabel ini tidak lagi diperlukan karena Post model sudah punya data like
  // Map<int, int> likeCounts = {};
  // Map<int, bool> likedPosts = {};
  bool isScrolled = false;

  // Controllers
  late ScrollController scrollController;
  late TextEditingController searchController;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  FeedController({
    required this.context,
    required this.vsync,
  });

  void initialize() {
    scrollController = ScrollController()..addListener(_onScroll);
    searchController = TextEditingController();
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );
    fadeAnimation =
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut);
    fetchPosts();
  }

  void _onScroll() {
    final scrolled = scrollController.offset > 0;
    if (scrolled != isScrolled) {
      isScrolled = scrolled;
      notifyListeners();
    }
  }

  Future<void> fetchPosts({String? tag, String sort = 'random'}) async {
    isLoading = true;
    notifyListeners();
    try {
      // fetchExplorePosts sudah mengembalikan data Post lengkap termasuk info like
      posts = await PostService().fetchExplorePosts();
    } catch (e) {
      print('Error memuat postingan explore: $e');
      _showErrorMessage('Gagal memuat postingan. Coba lagi.');
    } finally {
      isLoading = false;
      notifyListeners();
      if (posts.isNotEmpty) {
        animationController.forward(from: 0.0);
      }
    }
  }

  // Fungsi ini tidak lagi diperlukan karena data like sudah termasuk dalam Post model
  // Future<void> loadLikesForPosts(List<Post> postsToLoad) async { ... }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    isSearching = true;
    showSearchResults = true;
    notifyListeners();

    try {
      final authToken = await SecureStorage.getToken();
      final uri = Uri.parse('${ApiEndpoints.apiUrl}/users/search')
          .replace(queryParameters: {'username': query, 'full_name': query});


      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic>? usersListToProcess;

        if (responseData is List) {
          // If the API response is a JSON list directly
          usersListToProcess = responseData;
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('data') && responseData['data'] is List) {
          // If the API response is a JSON object with a 'data' key which is a list (original expectation)
          usersListToProcess = responseData['data'] as List<dynamic>;
        } else {
          // If the response format is neither a direct list nor a map with 'data':[List]
          print('Unexpected JSON format from API. Body: ${response.body}');
          // usersListToProcess remains null
        }

        if (usersListToProcess != null) {
          searchResults = usersListToProcess
              .map((item) => User.fromJson(item as Map<String, dynamic>)) // Added cast to Map<String, dynamic>
              .toList();
        } else {
          searchResults = [];
          // Only show error if the format was truly unexpected.
          if (!(responseData is List || (responseData is Map<String, dynamic> && responseData.containsKey('data') && responseData['data'] is List))) {
            _showErrorMessage('Format respons dari server tidak dikenal.');
          }
        }
      } else {
        // Log error for debugging
        print('Failed to search users. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to search users');
      }
    } catch (e) {
      print('Error searching users: $e');
      searchResults = [];
      _showErrorMessage('Gagal mencari pengguna. Coba lagi.');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchController.clear();
    showSearchResults = false;
    searchResults = [];
    isSearching = false;
    notifyListeners();
  }

  Future<void> onLikePost(Post post) async {
    final originalLiked = post.isLikedByUser;
    final originalCount = post.likesCount;

    // Optimistic Update: Langsung ubah data di model
    post.isLikedByUser = !originalLiked;
    post.likesCount += !originalLiked ? 1 : -1;
    notifyListeners();

    try {
      // --- PERBAIKAN DI SINI ---
      await LikeService().toggleLikeHttp(
        post.id,
        isCurrentlyLiked: originalLiked,
        currentLikesCount: originalCount,
      );
    } catch (e) {
      // Jika gagal, kembalikan ke state semula
      post.isLikedByUser = originalLiked;
      post.likesCount = originalCount;
      notifyListeners();
    }
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterDialog(),
    );
  }

  void navigateToPostDetail(Post post) {
    NavigationHelper.navigateToPostDetail(context, post.id, initialPost: post);
  }

  void _showErrorMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
