// lib/pages/feed_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/post_detail.dart';
import 'package:portal_si/pages/ranking_page.dart';
import '../components/bottom_navigation.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../widgets/feed/feed_header.dart';
import '../widgets/feed/feed_grid.dart';
import '../widgets/feed/search_results.dart';
import '../controllers/feed_controller.dart';
import '../utils/navigation_helper.dart';
import 'dashboard_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final FeedController _controller;
  final int _selectedIndex = 1;
  bool _isSiBoardPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = FeedController(
      context: context,
      vsync: this,
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
      Navigator.pushReplacementNamed(context, '/home');
    }
    // Tambahkan navigasi lain jika perlu
    else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  // Ubah parameter menjadi objek User
  void _onUserTap(User user) {
    // Pastikan NavigationHelper juga sudah diupdate untuk menerima User
    NavigationHelper.navigateToProfile2(context, user);
  }

// Ubah parameter menjadi objek User
  void _onSearchUserTap(User user) {
    _controller.clearSearch();
    _onUserTap(user);
  }

  void _handleBackPress(bool didPop) {
    if (!didPop) {
      // Perilaku default saat tombol back ditekan di halaman explore
      // bisa disesuaikan, misal kembali ke dashboard
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: Colors.transparent, // Beri warna dasar
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Ganti seluruh isi Column berdasarkan state pencarian
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                // Jika sedang mencari, tampilkan hasil pencarian.
                // Jika tidak, tampilkan feed grid.
                child: _controller.showSearchResults
                    ? _buildSearchResults()
                    : _buildFeedContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedContent() {
    return RefreshIndicator(
      onRefresh: _controller.fetchPosts,
      color: Theme.of(context).primaryColor,
      child: CustomScrollView(
        controller: _controller.scrollController,
        slivers: [
          // Panggil FeedGrid secara langsung di sini
          FeedGrid(
            isLoading: _controller.isLoading,
            posts: _controller.posts,
            fadeAnimation: _controller.fadeAnimation,
            onRefresh: _controller.fetchPosts,
            onLikePost: (post) => _controller.onLikePost(post),
            onPostTap: (post) => _controller.navigateToPostDetail(post),
            onUserTap: (user) => NavigationHelper.navigateToProfile2(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSlivers() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        if (_controller.showSearchResults) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildSearchResults(),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            FeedGrid(
              isLoading: _controller.isLoading,
              posts: _controller.posts,
              // --- 👇 PERBAIKAN DI SINI: Hapus parameter yang tidak ada ---
              // likeCounts: _controller.likeCounts,
              // likedPosts: _controller.likedPosts,
              fadeAnimation: _controller.fadeAnimation,
              onRefresh: _controller.fetchPosts,
              onLikePost: (post) => _controller.onLikePost(post),
              onPostTap: (post) => _controller.navigateToPostDetail(post),
              onUserTap: _onUserTap,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return FeedHeader(
      searchController: _controller.searchController,
      isScrolled: _controller.isScrolled,
      onSearchChanged: _controller.searchUsers,
      onClearSearch: _controller.clearSearch,
      onFilterTap: _controller.showFilterDialog,
    );
  }

  Widget _buildSearchResults() {
    // SearchResults sekarang menjadi widget utama di dalam Expanded
    // jadi tidak perlu lagi SliverFillRemaining
    return SearchResults(
      isSearching: _controller.isSearching,
      searchResults: _controller.searchResults,
      onUserTap: (user) {
        _controller.clearSearch();
        NavigationHelper.navigateToProfile2(context, user);
      },
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: _onBottomNavTapped,
    );
  }
}