// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../widgets/feed/feed_header.dart';
import '../widgets/feed/feed_grid.dart';
import '../widgets/feed/search_results.dart';
import '../controllers/feed_controller.dart';
import '../utils/secure_storage.dart';
import '../utils/navigation_helper.dart';
import 'dashboard_page.dart';
import 'other_profile_page.dart';
import 'profile_page.dart'; // Import ProfilePage

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final FeedController _controller;
  static const int _selectedIndex = 1;

  // Cache system UI overlay style untuk menghindari pembuatan berulang
  static const SystemUiOverlayStyle _systemUIOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = FeedController(
      context: context,
      vsync: this,
      onNavigateToDetail: _navigateToDetail,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetail(dynamic item) {
    _controller.navigateToPostDetail(item);
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;

    HapticFeedback.lightImpact();

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Method utama untuk navigate ke profile user
  void _onUserTap(Map<String, dynamic> user) async {
    await _navigateToUserProfile(user);
  }

  // Implementasi navigation yang diperbaiki
  Future<void> _navigateToUserProfile(Map<String, dynamic> user) async {
    try {
      final username = user['username'] ?? 'Unknown User';
      final userId = _extractUserId(user);
      final currentUserId = await SecureStorage.getUserId();

      debugPrint('User tap: $username (user_id: $userId)');
      debugPrint('Current user_id: $currentUserId');

      // Validasi user_id
      if (userId == null) {
        debugPrint('Warning: user_id tidak ditemukan dalam data user');
        _navigateToOtherProfile(username);
        return;
      }

      if (currentUserId == null) {
        debugPrint('Warning: current user_id tidak ditemukan di storage');
        _navigateToOtherProfile(username);
        return;
      }

      // Konversi ke string untuk perbandingan yang lebih aman
      final userIdStr = userId.toString();
      final currentUserIdStr = currentUserId.toString();

      // Jika user_id sama dengan user yang login
      if (userIdStr == currentUserIdStr) {
        debugPrint('Navigating to own profile (user_id: $userId)');
        _navigateToOwnProfile();
      } else {
        debugPrint('Navigating to other profile: $username (user_id: $userId)');
        _navigateToOtherProfile(username, userId: userId);
      }
    } catch (e) {
      debugPrint('Error in _navigateToUserProfile: $e');
      // Fallback ke other profile
      final username = user['username'] ?? 'Unknown User';
      _navigateToOtherProfile(username);
    }
  }

  // Navigate ke profile sendiri
  void _navigateToOwnProfile() {
    HapticFeedback.lightImpact();

    // Opsi 1: Gunakan pushReplacementNamed jika ProfilePage ada di bottom navigation
    Navigator.pushReplacementNamed(context, '/profile');

    // Opsi 2: Gunakan push jika ingin stack navigation
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ProfilePage()),
    // );
  }

  // Navigate ke profile orang lain
  void _navigateToOtherProfile(String username, {dynamic userId}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherProfilePage(
          username: username,
          // Pass userId jika diperlukan
        ),
      ),
    );
  }

  // Helper method untuk extract user_id dengan berbagai fallback
  dynamic _extractUserId(Map<String, dynamic> user) {
    // Coba berbagai kemungkinan key untuk user_id
    final possibleKeys = ['user_id', 'id', 'userId', 'uid'];

    // Cek di level utama
    for (final key in possibleKeys) {
      final value = user[key];
      if (value != null) {
        if (value is int || value is String) {
          return value;
        }
      }
    }

    // Cek di nested 'user' object
    final nestedUser = user['user'];
    if (nestedUser is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = nestedUser[key];
        if (value != null) {
          if (value is int || value is String) {
            return value;
          }
        }
      }
    }

    // Cek di nested 'profile' object (jika ada)
    final nestedProfile = user['profile'];
    if (nestedProfile is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = nestedProfile[key];
        if (value != null) {
          if (value is int || value is String) {
            return value;
          }
        }
      }
    }

    debugPrint('Warning: user_id tidak ditemukan dalam struktur data user');
    debugPrint('User data structure: ${user.keys.toList()}');

    return null;
  }

  // Method untuk user tap dari search results
  void _onSearchUserTap(Map<String, dynamic> user) {
    // Clear search terlebih dahulu
    _controller.clearSearch();

    // Kemudian navigate ke profile
    _onUserTap(user);
  }

  void _handleBackPress(bool didPop) {
    if (!didPop) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(_systemUIOverlayStyle);

    return PopScope(
      canPop: false,
      onPopInvoked: _handleBackPress,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _controller.fetchPosts,
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => FeedHeader(
        searchController: _controller.searchController,
        isScrolled: _controller.isScrolled,
        onSearchChanged: _controller.searchUsers,
        onClearSearch: _controller.clearSearch,
        onFilterTap: _controller.showFilterDialog,
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.showSearchResults) {
          return _buildSearchResults();
        }
        return _buildFeedGrid();
      },
    );
  }

  Widget _buildSearchResults() {
    return SearchResults(
      isSearching: _controller.isSearching,
      searchResults: _controller.searchResults,
      onUserTap: _onSearchUserTap,
    );
  }

  Widget _buildFeedGrid() {
    return FeedGrid(
      isLoading: _controller.isLoading,
      posts: _controller.posts,
      likeCounts: _controller.likeCounts,
      likedPosts: _controller.likedPosts,
      scrollController: _controller.scrollController,
      fadeAnimation: _controller.fadeAnimation,
      onRefresh: _controller.fetchPosts,
      onLikePost: _controller.onLikePost,
      onPostTap: _navigateToDetail,
      onUserTap: _onUserTap,
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: _onBottomNavTapped,
    );
  }
}
