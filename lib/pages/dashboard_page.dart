import 'package:flutter/material.dart';
import 'package:portal_si/pages/profile_page.dart';
import '../components/story_section.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';
import '../components/comment_section.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/services/post_service.dart';
import 'package:portal_si/services/like_service.dart';
import '../helper/time_helper.dart';
import '../utils/secure_storage.dart';
import 'dart:io'; // untuk exit(0)
import 'other_profile_page.dart';
import 'message_list_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<dynamic> _posts = [];
  bool _isLoading = true;
  Map<int, int> _likeCounts = {};
  Map<int, bool> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _initializeAnimations();
    _setupScrollListener();
  }

  Future<void> loadLikesForPosts(List<dynamic> posts) async {
    for (var post in posts) {
      final postId = post['post_id'];
      try {
        final likes = await LikeService().getLikes(postId);
        _likeCounts[postId] = likes.length;

        final currentUserId =
            await SecureStorage.getUserId(); // Pastikan method ini ada
        _likedPosts[postId] = likes.any(
          (like) => like['user_id'] == currentUserId,
        );
      } catch (e) {
        _likeCounts[postId] = 0;
        _likedPosts[postId] = false;
      }
    }
    setState(() {});
  }

  Future<void> _onLikePost(Map post, int index) async {
    print('Post data saat like: $post');

    final postId = post['post_id'];
    if (postId == null) {
      print('ERROR: postId null');
      return;
    }

    final success = await LikeService().toggleLike(postId);
    if (success) {
      print('Like berhasil dikirim');
      final updatedLikes = await LikeService().getLikes(postId);
      final currentUserId = await SecureStorage.getUserId(); // ✅ Tambahkan ini

      setState(() {
        _likeCounts[postId] = updatedLikes.length;
        _likedPosts[postId] = updatedLikes.any(
          (like) => like['user_id'] == currentUserId,
        );
      });
    } else {
      print('Gagal like');
    }
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
  }

  /// Setup scroll listener for app bar shadow effect
  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isScrolled = _scrollController.offset > 10;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    });
  }

  /// Fetch posts from API
  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().fetchAllPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Failed to load posts. Please try again.');
      }
    }
  }

  /// Show error message to user
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle bottom navigation tap
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    HapticFeedback.lightImpact();

    // Scroll to top when home tab is tapped
    if (index == 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Handle pull to refresh
  Future<void> _onRefresh() async {
    _refreshController.forward();

    try {
      await _fetchPosts();
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorMessage('Failed to refresh posts');
    } finally {
      await Future.delayed(Duration(milliseconds: 500));
      _refreshController.reverse();
    }
  }

  /// Show comment section as bottom sheet
  void _showCommentSection(dynamic post) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: CommentSection(post: post, scrollController: scrollController),
        ),
      ),
    );
  }

  /// Handle like action

  /// Handle bookmark action
  void _onBookmarkPost(dynamic post, int index) {
    HapticFeedback.lightImpact();
    // TODO: Implement bookmark functionality
    setState(() {
      _posts[index]['is_bookmarked'] =
          !(_posts[index]['is_bookmarked'] ?? false);
    });
  }

  /// Handle share action
  void _onSharePost(dynamic post) {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    _showErrorMessage('Share functionality coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlayStyle();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop(); // atau exit(0)
        }
      },

      child: Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        extendBodyBehindAppBar: false,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      ),
    );
  }

  /// Set system UI overlay style
  void _setSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Build app bar with scroll animation
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: _isScrolled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 300),
            style: TextStyle(
              color: Colors.black87,
              fontSize: _isScrolled ? 18 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            child: Text('Portal SI'),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MessageListPage()),
                );
              },
            ),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFF0D0), // peach lembut di kiri
            Color(0xFFFFFFFF), // putih di tengah
            Color(0xFFDFFEF8), // mint lembut di kanan
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.deepOrangeAccent,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 40,
        child: CustomScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(),
          slivers: [_buildStorySection(), _buildPostsList()],
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F0), Colors.white, Color(0xFFF0FDFA)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepOrangeAccent,
              ),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading posts...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFF0D0), // peach lembut di kiri
            Color(0xFFFFFFFF), // putih di tengah
            Color(0xFFDFFEF8), // mint lembut di kanan
          ],
          stops: [0.0, 0.5, 1.0], // posisi transisi warna
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or check back later',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// Build story section with animation
  Widget _buildStorySection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _refreshAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -30 * _refreshAnimation.value),
            child: Opacity(
              opacity: 1 - (_refreshAnimation.value * 0.4),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                child: StorySection(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build posts list
  Widget _buildPostsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = _posts[index];
        return _buildAnimatedPost(
          delay: index * 100,
          post: Container(
            margin: EdgeInsets.only(bottom: 16),
            child: PostCard(
              username: post['user']['username'] ?? 'Unknown',
              timeAgo: timeAgoFromDate(post['created_at']),
              imageUrl: post['media_url'] ?? '',
              likes: _likeCounts[post['post_id']] ?? 0,
              comments: post['comments_count'] ?? 0,
              content: post['caption'] ?? '',
              isVerified: post['user']['is_verified'] ?? false,
              isLiked: _likedPosts[post['post_id']] ?? false,
              isBookmarked: post['is_bookmarked'] ?? false,
              profileImageUrl: post['user']['profile_picture_url'] ?? '',
              user: post['user'],
              onLike: () => _onLikePost(post, index),
              onBookmark: () => _onBookmarkPost(post, index),
              onShare: () => _onSharePost(post),
              onComment: () => _showCommentSection(post),
              postId: post['post_id'],
              onProfileTap: () async {
                final currentUserId = await SecureStorage.getUserId();
                final tappedUserId = int.tryParse(
                  post['user']['user_id'].toString(),
                );
                print('Current User ID: $currentUserId');
                print('Tapped User ID: $tappedUserId');

                if (tappedUserId == currentUserId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OtherProfilePage(userId: tappedUserId!),
                    ),
                  );
                }
              },
              // Add comment callback
            ),
          ),
        );
      }, childCount: _posts.length),
    );
  }

  /// Build animated post with smooth entrance animation
  Widget _buildAnimatedPost({required int delay, required Widget post}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: post),
        );
      },
    );
  }
}
