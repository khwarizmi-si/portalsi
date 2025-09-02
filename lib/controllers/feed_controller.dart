// lib/controllers/feed_controller.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/pages/post_detail_page.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';
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
      posts = await PostService().fetchExplorePosts(tag: tag, sort: sort);
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
      // --- 👇 PERBAIKAN DI SINI ---
      final uri = Uri.parse('https://api-new.portalsi.com/api/users/search')
          .replace(queryParameters: {'username': query}); // Diubah dari 'q'


      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Anda bisa sederhanakan ini jika kunci respons sudah pasti
        final usersJson = data['data'] as List?;
        if (usersJson != null) {
          searchResults = usersJson.map((item) => User.fromJson(item)).toList();
        } else {
          searchResults = [];
        }
      } else {
        // Log error untuk debugging
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
      // Panggil metode HTTP dari LikeService
      await LikeService().toggleLikeHttp(post.id);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          postId: post.id,
          initialPost: post,
          // Parameter lain tidak perlu di-pass karena sudah ada di dalam `initialPost`
          username: post.user.username,
          timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
          imageUrl: post.mediaUrl ?? '',
          content: post.caption ?? '',
          comments: post.commentsCount,
          profileImageUrl: post.user.profilePictureUrl ?? '',
          likes: post.likesCount,
          isVerified: post.user.isVerified,
          isLiked: post.isLikedByUser,
        ),
      ),
    );
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