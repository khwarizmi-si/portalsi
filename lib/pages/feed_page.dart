// lib/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../widgets/feed/feed_header.dart';
import '../widgets/feed/feed_grid.dart';
import '../widgets/feed/search_results.dart';
import '../controllers/feed_controller.dart';
import 'dashboard_page.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with TickerProviderStateMixin {
  late FeedController _controller;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
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
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _controller.fetchPosts,
          color: Theme.of(context).primaryColor,
          child: SafeArea(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => FeedHeader(
                    searchController: _controller.searchController,
                    isScrolled: _controller.isScrolled,
                    onSearchChanged: _controller.searchUsers,
                    onClearSearch: _controller.clearSearch,
                    onFilterTap: _controller.showFilterDialog,
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (_controller.showSearchResults) {
                        return SearchResults(
                          isSearching: _controller.isSearching,
                          searchResults: _controller.searchResults,
                          onUserTap: (user) {
                            print('Navigate to profile: ${user['username']}');
                          },
                        );
                      }

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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      ),
    );
  }
}
