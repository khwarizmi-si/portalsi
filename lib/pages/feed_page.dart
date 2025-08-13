// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../widgets/feed/feed_header.dart';
import '../widgets/feed/feed_grid.dart';
import '../widgets/feed/search_results.dart';
import '../controllers/feed_controller.dart';
import '../utils/navigation_helper.dart'; // Helper Anda yang sebenarnya
import 'dashboard_page.dart'; // Digunakan di _handleBackPress

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final FeedController _controller;
  final int _selectedIndex = 1;

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
    _controller = FeedController(
      context: context,
      vsync: this,
      // onNavigateToDetail: (item) => _controller.navigateToPostDetail(item),
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();

    if (index == 0) {
      // Kembali menggunakan Navigator standar karena tidak ada helper generik
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  /// Metode ini menjadi SANGAT sederhana berkat NavigationHelper
  void _onUserTap(Map<String, dynamic> user) {
    // Seluruh logika kompleks kini ditangani oleh helper
    NavigationHelper.navigateToProfile(context, user);
  }

  void _onSearchUserTap(Map<String, dynamic> user) {
    _controller.clearSearch();
    // Cukup panggil _onUserTap yang sudah bersih
    _onUserTap(user);
  }

  void _handleBackPress(bool didPop) {
    if (!didPop) {
      // Kembali menggunakan Navigator standar
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUIOverlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvoked: _handleBackPress,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNavigation(),
        ),
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
      builder: (_, __) => FeedHeader(
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
      builder: (_, __) {
        return _controller.showSearchResults
            ? _buildSearchResults()
            : _buildFeedGrid();
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

// Di dalam file lib/pages/feed_page.dart

  Widget _buildFeedGrid() {
    return FeedGrid(
      isLoading: _controller.isLoading,
      posts: _controller.posts, // Sekarang ini adalah List<Post>
      likeCounts: _controller.likeCounts,
      likedPosts: _controller.likedPosts,
      scrollController: _controller.scrollController,
      fadeAnimation: _controller.fadeAnimation,
      onRefresh: _controller.fetchPosts,
      // --- PERBAIKAN DI SINI ---
      onLikePost: (post) =>
          _controller.onLikePost(post), // Langsung teruskan objek post
      onPostTap: (post) => _controller
          .navigateToPostDetail(post), // Langsung teruskan objek post
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
