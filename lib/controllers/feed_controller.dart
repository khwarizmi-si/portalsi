// lib/controllers/feed_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../utils/secure_storage.dart';
import '../helper/time_helper.dart';
import '../pages/post_detail_page.dart';
import '../widgets/feed/filter_dialog.dart';

class FeedController extends ChangeNotifier {
  final BuildContext context;
  final TickerProvider vsync;
  final Function(dynamic) onNavigateToDetail;

  // Controllers
  late ScrollController scrollController;
  late TextEditingController searchController;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  // State variables
  bool isScrolled = false;
  List<dynamic> posts = [];
  List<dynamic> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool showSearchResults = false;
  Map<int, int> likeCounts = {};
  Map<int, bool> likedPosts = {};

  FeedController({
    required this.context,
    required this.vsync,
    required this.onNavigateToDetail,
  });

  void initialize() {
    scrollController = ScrollController();
    searchController = TextEditingController();

    animationController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 800),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    scrollController.addListener(_onScroll);
    fetchPosts();
  }

  void _onScroll() {
    bool scrolled = scrollController.offset > 0;
    if (scrolled != isScrolled) {
      isScrolled = scrolled;
      notifyListeners();
    }
  }

  Future<void> fetchPosts({String? tag, String sort = 'random'}) async {
    try {
      isLoading = true;
      notifyListeners();

      final fetchedPosts = await PostService().fetchExplorePosts(
        tag: tag,
        sort: sort,
      );

      posts = fetchedPosts;
      isLoading = false;
      notifyListeners();

      await loadLikesForPosts(fetchedPosts);

      if (posts.isNotEmpty) {
        animationController.forward();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      _showErrorMessage('Failed to load posts. Please try again.');
    }
  }

  Future<void> loadLikesForPosts(List<dynamic> posts) async {
    final currentUserId = await SecureStorage.getUserId();
    await Future.wait(
      posts.map((post) async {
        final postId = int.tryParse(post['post_id'].toString());
        if (postId == null) return;

        try {
          final likes = await LikeService().getLikes(postId);
          likeCounts[postId] = likes.length;
          likedPosts[postId] = likes.any(
            (like) => like['user_id'] == currentUserId,
          );
        } catch (e) {
          print("Error loading likes for post $postId: $e");
          likeCounts[postId] = 0;
          likedPosts[postId] = false;
        }
      }),
    );
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      showSearchResults = false;
      searchResults = [];
      isSearching = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    showSearchResults = true;
    notifyListeners();

    try {
      final authToken = await SecureStorage.getToken();
      final uri = Uri.parse(
        'https://api.portalsi.com/api/users/search',
      ).replace(queryParameters: {'username': query, 'full_name': query});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> users = [];

        if (data is Map<String, dynamic>) {
          users = data['data'] ?? data['users'] ?? [];
        } else if (data is List) {
          users = data;
        }

        searchResults = users;
        isSearching = false;
        notifyListeners();
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      print('Error searching users: $e');
      searchResults = [];
      isSearching = false;
      notifyListeners();
      _showErrorMessage('Failed to search users. Please try again.');
    }
  }

  void clearSearch() {
    searchController.clear();
    showSearchResults = false;
    searchResults = [];
    isSearching = false;
    notifyListeners();
  }

  Future<void> onLikePost(Map post, int index) async {
    final postId = int.tryParse(post['post_id'].toString())!;
    final currentLiked = likedPosts[postId] ?? false;

    // Optimistic update
    likedPosts[postId] = !currentLiked;
    likeCounts[postId] = (likeCounts[postId] ?? 0) + (currentLiked ? -1 : 1);
    notifyListeners();

    // Send to server
    final success = await LikeService().toggleLike(postId);

    if (!success) {
      // Rollback on failure
      likedPosts[postId] = currentLiked;
      likeCounts[postId] = (likeCounts[postId] ?? 0) + (currentLiked ? 1 : -1);
      notifyListeners();
      print('Gagal mengirim like ke server');
    }
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterDialog(),
    );
  }

  void navigateToPostDetail(dynamic item) {
    final user = item['user'];
    final postId = int.tryParse(item['post_id'].toString());

    if (postId == null) {
      print('ERROR: postId null, tidak bisa navigasi');
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PostDetailPage(
          username: user?['username'] ?? 'Unknown User',
          timeAgo: item['created_at'] != null
              ? timeAgoFromDate(item['created_at'])
              : 'Unknown time',
          imageUrl: item['media_url'] ?? '',
          content: item['caption'] ?? '',
          likes: likeCounts[postId] ?? 0,
          comments: item['comments_count'] ?? 0,
          profileImageUrl: user?['profile_picture_url'] ?? '',
          isVerified: user?['is_verified'] ?? false,
          postId: postId,
          isLiked: likedPosts[postId] ?? false,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: Offset(0.3, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: fetchPosts,
        ),
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
