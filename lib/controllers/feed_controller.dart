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

class FeedController extends ChangeNotifier {
  final BuildContext context;
  final TickerProvider vsync;

  // State variables
  List<Post> posts = [];
  List<User> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool showSearchResults = false;
  Map<int, int> likeCounts = {};
  Map<int, bool> likedPosts = {};
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
    // Cek apakah posisi scroll lebih dari 0
    final scrolled = scrollController.offset > 0;
    // Hanya panggil notifyListeners jika nilainya berubah untuk efisiensi
    if (scrolled != isScrolled) {
      isScrolled = scrolled;
      notifyListeners();
    }
  }

  Future<void> fetchPosts({String? tag, String sort = 'random'}) async {
    isLoading = true;
    notifyListeners();
    try {
      final fetchedPosts =
          await PostService().fetchExplorePosts(tag: tag, sort: sort);
      posts = fetchedPosts;
      await loadLikesForPosts(fetchedPosts);
    } catch (e) {
      print(' $e'); // Tambahkan print untuk debug
      _showErrorMessage('Gagal memuat postingan. Coba lagi.');
    } finally {
      isLoading = false;
      notifyListeners();
      if (posts.isNotEmpty) {
        animationController.forward(from: 0.0);
      }
    }
  }

  // --- PERBAIKAN UTAMA DI SINI ---
  Future<void> loadLikesForPosts(List<Post> postsToLoad) async {
    // --- PERBAIKAN DI SINI ---
    // Langsung dapatkan ID sebagai int? karena getUserId sudah melakukannya untuk kita.
    final currentUserId = await SecureStorage.getUserId();

    // Jika ID tidak valid (null), jangan lanjutkan proses.
    if (currentUserId == null) return;

    await Future.wait(
      postsToLoad.map((post) async {
        try {
          final likes = await LikeService().getLikes(post.id);
          likeCounts[post.id] = likes.length;

          // Perbandingan sekarang sudah benar (int == int)
          likedPosts[post.id] =
              likes.any((like) => like.user.id == currentUserId);
        } catch (e) {
          // Fallback jika gagal mengambil data likes
          likeCounts[post.id] = post.likesCount;
          likedPosts[post.id] = post.isLikedByUser;
        }
      }),
    );
    notifyListeners();
  }

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
      final uri = Uri.parse('https://api.portalsi.com/api/users/search')
          .replace(
              queryParameters: {'q': query}); // API search biasanya pakai 'q'

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usersJson = (data['data'] ?? data['users'] ?? []);
        if (usersJson is List) {
          searchResults = usersJson.map((item) => User.fromJson(item)).toList();
        } else {
          searchResults = [];
        }

        // Ubah setiap item JSON menjadi objek User
        searchResults = usersJson.map((item) => User.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
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
    final postId = post.id;
    final originalLiked = likedPosts[postId] ?? false;
    final originalCount = likeCounts[postId] ?? 0;

    likedPosts[postId] = !originalLiked;
    likeCounts[postId] = originalCount + (!originalLiked ? 1 : -1);
    notifyListeners();

    try {
      await LikeService().toggleLike(postId);
    } catch (e) {
      likedPosts[postId] = originalLiked;
      likeCounts[postId] = originalCount;
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
          username: post.user.username,
          timeAgo: post.createdAt.toString(), // fungsi custom format waktu
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
