import 'package:flutter/material.dart';
import '../components/story_section.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/services/post_service.dart';
import '../helper/time_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _refreshController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    });
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().fetchAllPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Tangani error, bisa tampilkan SnackBar, Alert, dll
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    HapticFeedback.lightImpact();

    if (index == 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onRefresh() async {
    _refreshController.forward();
    await Future.delayed(Duration(milliseconds: 1500));
    _refreshController.reverse();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Ganti warna status bar dan navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFF0E0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF0E0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Color(0xFFFFF0E0),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: _isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
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
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                color: Colors.black,
                fontSize: _isScrolled ? 18 : 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              child: Text('Portal SI'),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.black87),
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFF0D0), // soft orange/peach kiri
                    Colors.white, // putih tengah
                    Color(0xFFDFFEF8), // mint/cyan kanan
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: Colors.deepOrangeAccent,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _refreshAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -20 * _refreshAnimation.value),
                            child: Opacity(
                              opacity: 1 - (_refreshAnimation.value * 0.3),
                              child: StorySection(),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 8,
                        color: Colors.transparent,
                        margin: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = _posts[index];
                        return _buildAnimatedPost(
                          delay: index * 100,
                          post: PostCard(
                            username: post['user']['username'],
                            timeAgo: timeAgoFromDate(post['created_at']),
                            imageUrl: post['media_url'] ?? '',
                            likes: post['likes_count'] ?? 0,
                            comments: post['comments_count'] ?? 0,
                            content: post['caption'] ?? '',
                            isVerified: post['user']['is_verified'] ?? false,
                            isLiked: post['is_liked'] ?? false,
                            isBookmarked: post['is_bookmarked'] ?? false,
                            profileImageUrl:
                                post['user']['profile_picture_url'] ?? '',
                            user: post['user'],
                            onLike: () {
                              // TODO: tambahkan logika like di sini
                            },
                            onBookmark: () {
                              // TODO: tambahkan logika bookmark di sini
                            },
                            onShare: () {
                              // TODO: tambahkan logika share di sini
                            },
                          ),
                        );
                      }, childCount: _posts.length),
                    ),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildAnimatedPost({required int delay, required Widget post}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: post),
        );
      },
    );
  }
}
