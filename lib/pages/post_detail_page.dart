import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../components/post_card.dart';
import 'dashboard_page.dart';
import '../components/bottom_navigation.dart';
import '../helper/time_helper.dart'; // Pastikan ada fungsi timeAgoFromDate()

class PostDetailPage extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String imageUrl;
  final String content;
  final int likes;
  final int comments;
  final String profileImageUrl;
  final bool isVerified;
  final int postId;

  const PostDetailPage({
    Key? key,
    required this.username,
    required this.timeAgo,
    required this.imageUrl,
    required this.content,
    required this.likes,
    required this.comments,
    required this.profileImageUrl,
    required this.isVerified,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _allPosts = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchRelatedPosts();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> fetchRelatedPosts() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.portalsi.com/api/posts'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allPosts = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _showEnhancedPostPreview(Map<String, dynamic> item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: _buildPreviewDialog(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewDialog(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.network(
                  item['media_url'],
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    item['user']['username'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['caption'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _allPosts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _buildMainPost();
          if (index == _allPosts.length + 1) return const SizedBox(height: 100);
          return _buildRelatedPost(_allPosts[index - 1]);
        },
      ),
    );
  }

  Widget _buildMainPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PostCard(
        postId: widget.postId,
        username: widget.username,
        timeAgo: widget.timeAgo,
        imageUrl: widget.imageUrl,
        content: widget.content,
        likes: widget.likes,
        comments: widget.comments,
        isVerified: widget.isVerified,
        profileImageUrl: widget.profileImageUrl,
        isLiked: false,
        isBookmarked: false,
        user: {}, // Ganti dengan user jika ada
        onLike: () {},
        onBookmark: () {},
        onShare: () {},
        onComment: () {},
      ),
    );
  }

  Widget _buildRelatedPost(Map<String, dynamic> post) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showEnhancedPostPreview(post),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: PostCard(
            postId: widget.postId,
            username: post['user']['username'],
            timeAgo: timeAgoFromDate(post['created_at']),
            imageUrl: post['media_url'] ?? '',
            likes: post['likes_count'] ?? 0,
            comments: post['comments_count'] ?? 0,
            content: post['caption'] ?? '',
            isVerified: post['user']['is_verified'] ?? false,
            isLiked: post['is_liked'] ?? false,
            isBookmarked: post['is_bookmarked'] ?? false,
            profileImageUrl: post['user']['profile_picture_url'] ?? '',
            user: post['user'],
            onLike: () {},
            onBookmark: () {},
            onShare: () {},
            onComment: () {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 0,
          title: const Text(
            'Detail Postingan',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundGradient(),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: Colors.transparent),
              ),
            ),
            SafeArea(child: _buildPostsList()),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFF3E5F5),
            Color(0xFFE8F5E9),
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}
