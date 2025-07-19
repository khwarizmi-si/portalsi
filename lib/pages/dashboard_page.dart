import 'package:flutter/material.dart';
import '../components/story_section.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();

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
      body: Container(
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
                delegate: SliverChildListDelegate([
                  _buildAnimatedPost(
                    delay: 0,
                    post: PostCard(
                      username: 'uwangraph',
                      timeAgo: '10 jam',
                      imageUrl:
                          'https://i.pinimg.com/736x/e5/b2/e2/e5b2e25471789ef3d4fe8b9657a16d27.jpg',
                      likes: 99,
                      comments: 66,
                      content:
                          'Bingung cari font buat desain Ramadhan? Tenang, kita udah siapin rekomendasi terbaik buat kalian! 😊\n\nSwipe buat lihat lebih banyak pilihan! 📱',
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildAnimatedPost(
                    delay: 100,
                    post: PostCard(
                      username: 'uwangraph',
                      timeAgo: '11 jam',
                      imageUrl:
                          'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&h=400&fit=crop',
                      likes: 45,
                      comments: 23,
                      content:
                          'Tips desain yang mudah dipahami untuk pemula! 🎨',
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildAnimatedPost(
                    delay: 200,
                    post: PostCard(
                      username: 'designpro',
                      timeAgo: '1 hari',
                      imageUrl:
                          'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=400&h=400&fit=crop',
                      likes: 128,
                      comments: 45,
                      content:
                          'Inspirasi color palette terbaru untuk project 2024! 🎨✨',
                    ),
                  ),
                  SizedBox(height: 100), // Padding bottom untuk nav bar
                ]),
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
