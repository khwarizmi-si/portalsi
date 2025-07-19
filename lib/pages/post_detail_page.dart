import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';

class PostDetailPage extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String imageUrl;
  final String content;
  final int likes;
  final int comments;

  const PostDetailPage({
    Key? key,
    required this.username,
    required this.timeAgo,
    required this.imageUrl,
    required this.content,
    required this.likes,
    required this.comments,
  }) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Enhanced posts data with better organization
  static const List<Map<String, dynamic>> _allPosts = [
    {
      'image':
          'https://i.pinimg.com/736x/e5/b2/e2/e5b2e25471789ef3d4fe8b9657a16d27.jpg',
      'title': 'HUT',
      'subtitle': 'Design Collection',
      'category': 'Design',
      'likes': 245,
      'comments': 18,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      'title': 'LORD',
      'subtitle': 'Game UI Design',
      'category': 'Gaming',
      'likes': 189,
      'comments': 24,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400',
      'title': 'JONAS',
      'subtitle': 'Character Design',
      'category': 'Character',
      'likes': 312,
      'comments': 45,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=400',
      'title': 'SQUIDWARD',
      'subtitle': 'Animation',
      'category': 'Animation',
      'likes': 567,
      'comments': 89,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
      'title': 'PRO SKYLAR',
      'subtitle': 'Sports Design',
      'category': 'Sports',
      'likes': 423,
      'comments': 67,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1566492031773-4f4e44671d66?w=400',
      'title': 'NINJA',
      'subtitle': 'Game Interface',
      'category': 'Gaming',
      'likes': 298,
      'comments': 34,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=400',
      'title': 'GRADIENT',
      'subtitle': 'Color Palette',
      'category': 'Design',
      'likes': 156,
      'comments': 12,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            // Image with overlay gradient
            Stack(
              children: [
                Image.network(
                  item['image'],
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
                // Category badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['subtitle'],
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(
                        Icons.favorite_outline,
                        '${item['likes']}',
                        Colors.red[400]!,
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        Icons.chat_bubble_outline,
                        '${item['comments']}',
                        Colors.blue[400]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFFFF8E1),
            Color(0xFFF3E5F5),
            Color(0xFFE8F5E9), // typo fixed
            Colors.white,
          ],

          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _allPosts.length + 2, // +1 for main post, +1 for spacing
        itemBuilder: (context, index) {
          if (index == 0) {
            // Main post
            return _buildMainPost();
          } else if (index == _allPosts.length + 1) {
            // Bottom spacing
            return const SizedBox(height: 100);
          } else {
            // Related posts
            final item = _allPosts[index - 1];
            return _buildRelatedPost(item, index - 1);
          }
        },
      ),
    );
  }

  Widget _buildMainPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PostCard(
        username: widget.username,
        timeAgo: widget.timeAgo,
        imageUrl: widget.imageUrl,
        content: widget.content,
        likes: widget.likes,
        comments: widget.comments,
      ),
    );
  }

  Widget _buildRelatedPost(Map<String, dynamic> item, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _showEnhancedPostPreview(item),
          onTap: () {
            // Haptic feedback
            // HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: PostCard(
              username: 'randomuser',
              timeAgo: 'Baru saja',
              imageUrl: item['image'],
              content: item['subtitle'],
              likes: item['likes'],
              comments: item['comments'],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
