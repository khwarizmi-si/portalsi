import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import 'post_detail_page.dart';
import 'package:portal_si/services/post_service.dart';
import '../helper/time_helper.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with TickerProviderStateMixin {
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isScrolled = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<dynamic> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Setup scroll listener untuk header shadow
    _scrollController.addListener(() {
      bool isScrolled = _scrollController.offset > 0;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    });

    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().getExplorePosts();
      if (mounted) {
        setState(() {
          _feedItems = posts;
          _isLoading = false;
        });

        // Mulai animasi setelah data berhasil dimuat
        if (_feedItems.isNotEmpty) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Failed to load posts. Please try again.');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchPosts,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Discover',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showFilterDialog();
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                // Implement search functionality here
                // _filterPosts(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Memuat postingan...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Error handling dilakukan melalui SnackBar di _showErrorMessage()

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada postingan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Postingan akan muncul di sini',
              style: TextStyle(color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchPosts, child: Text('Refresh')),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridItem(_feedItems[index], index),
                childCount: _feedItems.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildGridItem(dynamic item, int index) {
    // Validasi data item
    if (item == null) {
      return _buildPlaceholderItem();
    }

    final user = item['user'];
    final imageUrl = item['media_url'] ?? '';
    final caption = item['caption'] ?? '';
    final username = user?['username'] ?? 'Unknown User';
    final createdAt = item['created_at'];

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToDetail(item);
          },
          child: Hero(
            tag: 'post_$index',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background untuk loading state
                    Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    // Image
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[600],
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Gambar tidak\ndapat dimuat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (caption.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (createdAt != null) ...[
                            SizedBox(height: 4),
                            Text(
                              timeAgoFromDate(createdAt),
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderItem() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: Center(
        child: Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
      ),
    );
  }

  void _navigateToDetail(dynamic item) {
    final user = item['user'];
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
          likes: item['likes_count'] ?? 0,
          comments: item['comments_count'] ?? 0,
          profileImageUrl: user?['profile_picture_url'] ?? '',
          isVerified: user?['is_verified'] ?? false,
          postId: item['id'],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter & Sort',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Most Popular'),
              onTap: () {
                Navigator.pop(context);
                // Implement sort logic
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Most Recent'),
              onTap: () {
                Navigator.pop(context);
                // Implement sort logic
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Most Liked'),
              onTap: () {
                Navigator.pop(context);
                // Implement sort logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
