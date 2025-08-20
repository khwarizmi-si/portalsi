

// lib/pages/feed_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/ranking_page.dart';
import '../components/bottom_navigation.dart';
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
  }

  void _onUserTap(Map<String, dynamic> user) {
    NavigationHelper.navigateToProfile(context, user);
  }

  void _onSearchUserTap(Map<String, dynamic> user) {
    _controller.clearSearch();
    _onUserTap(user);
  }

  void _handleBackPress(bool didPop) {
    if (!didPop) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => const RankingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // hanya jika pakai AutomaticKeepAliveClientMixin
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUIOverlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvoked: _handleBackPress,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFF0D0),
                  Color(0xFFFFFFFF),
                  Color(0xFFDFFEF8),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: _buildBody(),
          ),
          bottomNavigationBar: _buildBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildSIBoardButton() {
    // Gunakan AnimatedContainer untuk animasi yang halus
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: _isSiBoardPressed
          ? (Matrix4.identity()..scale(0.96)) // Efek mengecil saat ditekan
          : Matrix4.identity(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        // Ganti GestureDetector dengan Listener untuk kontrol lebih
        child: Listener(
          onPointerDown: (_) => setState(() => _isSiBoardPressed = true),
          onPointerUp: (_) {
            setState(() => _isSiBoardPressed = false);
            // Navigasi ke halaman ranking setelah tombol dilepas
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft, // Tipe animasi dari kanan ke kiri
                child: const RankingPage(),
              ),
            );
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFF9E9).withOpacity(0.8),
                  const Color(0xFFFFEFB3).withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isSiBoardPressed ? [] : [ // Hilangkan shadow saat ditekan
                BoxShadow(
                  color: Colors.amber.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF2D3748), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            fontFamily: 'Poppins',
                          ),
                          children: [
                            TextSpan(
                              text: 'SI ',
                              style: TextStyle(color: Color(0xFFF59E0B)),
                            ),
                            TextSpan(text: 'Board'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lihat peringkat dan portofolio santri',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF2D3748), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PERBAIKAN UTAMA DI SINI ---
  Widget _buildBody() {
    return SafeArea(
      // 1. Gunakan Column untuk memisahkan bagian statis dan scrollable
      child: Column(
        children: [
          // Bagian ini sekarang statis dan TIDAK akan ikut scroll
          _buildHeader(),

          // 2. Gunakan Expanded agar area scroll mengisi sisa ruang
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.fetchPosts,
              color: Theme.of(context).primaryColor,
              child: CustomScrollView(
                controller: _controller.scrollController,
                slivers: [
                  // 3. Header sudah dipindah keluar, jadi kita hanya menampilkan konten di sini
                  _buildContentSlivers(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Buat method baru untuk membangun sliver konten
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

        // Jika tidak mencari, tampilkan Tombol SI Board dan FeedGrid
        return SliverMainAxisGroup(
          slivers: [
            // SliverToBoxAdapter(child: _buildSIBoardButton()),
            FeedGrid(
              isLoading: _controller.isLoading,
              posts: _controller.posts,
              likeCounts: _controller.likeCounts,
              likedPosts: _controller.likedPosts,
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

  Widget _buildSearchResults() {
    return SearchResults(
      isSearching: _controller.isSearching,
      searchResults: _controller.searchResults,
      onUserTap: _onSearchUserTap,
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: _onBottomNavTapped,
    );
  }
}