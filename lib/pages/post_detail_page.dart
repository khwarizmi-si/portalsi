import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/utils/secure_storage.dart';
import 'package:portal_si/services/like_service.dart';
import 'package:portal_si/services/comment_service.dart';
import '../components/post_card.dart';
import 'dashboard_page.dart';
import '../components/bottom_navigation.dart';
import '../helper/time_helper.dart';
import 'other_profile_page.dart'; // Import OtherProfilePage
import 'profile_page.dart'; // Import ProfilePage
import 'dart:math';

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
  final bool isLiked;
  final int? userId; // Tambahkan userId untuk main post
  final Map<String, dynamic>? user; // Tambahkan user data

  const PostDetailPage({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.imageUrl,
    required this.content,
    required this.likes,
    required this.comments,
    required this.profileImageUrl,
    required this.isVerified,
    required this.postId,
    this.isLiked = false,
    this.userId,
    this.user,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _relatedPosts = [];
  bool _isLoadingRelated = true;

  // Like functionality
  Map<int, int> _likeCounts = {};
  Map<int, bool> _likedPosts = {};
  late bool _currentPostLiked;
  late int _currentPostLikes;

  @override
  void initState() {
    super.initState();
    _currentPostLiked = widget.isLiked;
    _currentPostLikes = widget.likes;
    _initializeAnimations();
    _fetchRelatedPosts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  // ✅ Profile Navigation Logic
  Future<void> _navigateToProfile(Map<String, dynamic> user) async {
    try {
      final username = user['username'] ?? 'Unknown User';
      final userId = _extractUserId(user);
      final currentUserId = await SecureStorage.getUserId();

      debugPrint('Profile tap: $username (user_id: $userId)');
      debugPrint('Current user_id: $currentUserId');

      // Validasi user_id
      if (userId == null) {
        debugPrint('Warning: user_id tidak ditemukan dalam data user');
        _navigateToOtherProfile(username);
        return;
      }

      if (currentUserId == null) {
        debugPrint('Warning: current user_id tidak ditemukan di storage');
        _navigateToOtherProfile(username);
        return;
      }

      // Konversi ke string untuk perbandingan yang lebih aman
      final userIdStr = userId.toString();
      final currentUserIdStr = currentUserId.toString();

      // Jika user_id sama dengan user yang login
      if (userIdStr == currentUserIdStr) {
        debugPrint('Navigating to own profile (user_id: $userId)');
        _navigateToOwnProfile();
      } else {
        debugPrint('Navigating to other profile: $username (user_id: $userId)');
        _navigateToOtherProfile(username, userId: userId);
      }
    } catch (e) {
      debugPrint('Error in _navigateToProfile: $e');
      // Fallback ke other profile
      final username = user['username'] ?? 'Unknown User';
      _navigateToOtherProfile(username);
    }
  }

  // Navigate ke profile sendiri
  void _navigateToOwnProfile() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacementNamed(context, '/profile');
  }

  // Navigate ke profile orang lain
  void _navigateToOtherProfile(String username, {dynamic userId}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherProfilePage(
          username: username,
        ),
      ),
    );
  }

  // Helper method untuk extract user_id
  dynamic _extractUserId(Map<String, dynamic> user) {
    final possibleKeys = ['user_id', 'id', 'userId', 'uid'];

    // Cek di level utama
    for (final key in possibleKeys) {
      final value = user[key];
      if (value != null) {
        if (value is int || value is String) {
          return value;
        }
      }
    }

    // Cek di nested 'user' object
    final nestedUser = user['user'];
    if (nestedUser is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = nestedUser[key];
        if (value != null) {
          if (value is int || value is String) {
            return value;
          }
        }
      }
    }

    return null;
  }

  // Profile tap handler untuk main post
  void _onMainPostProfileTap() {
    final mainPostUser = widget.user ??
        {
          'username': widget.username,
          'profile_picture_url': widget.profileImageUrl,
          'is_verified': widget.isVerified,
          'user_id': widget.userId,
        };
    _navigateToProfile(mainPostUser);
  }

  // Profile tap handler untuk related posts
  void _onRelatedPostProfileTap(Map<String, dynamic> post) {
    final user = post['user'] ?? {};
    _navigateToProfile(user);
  }

  // ✅ Implementasi like functionality untuk post utama
  Future<void> _onLikeMainPost() async {
    final currentLiked = _currentPostLiked;

    // Optimistic update
    setState(() {
      _currentPostLiked = !currentLiked;
      _currentPostLikes += currentLiked ? -1 : 1;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Kirim ke server
    final success = await LikeService().toggleLike(widget.postId);

    // Rollback jika gagal
    if (!success) {
      setState(() {
        _currentPostLiked = currentLiked;
        _currentPostLikes += currentLiked ? 1 : -1;
      });
      _showErrorSnackBar('Failed to update like');
    }
  }

  // ✅ Comment functionality untuk main post
  Future<void> _onCommentMainPost() async {
    showCommentSheet(context, widget.postId);
  }

  // ✅ Comment functionality untuk related posts
  Future<void> _onCommentRelatedPost(Map<String, dynamic> post) async {
    final postId = post['post_id'] as int;
    showCommentSheet(context, postId);
  }

  Future<void> _onLikeRelatedPost(Map<String, dynamic> post) async {
    final postId = post['post_id'] as int;
    final currentLiked = _likedPosts[postId] ?? false;

    setState(() {
      _likedPosts[postId] = !currentLiked;
      _likeCounts[postId] =
          (_likeCounts[postId] ?? 0) + (currentLiked ? -1 : 1);
    });

    HapticFeedback.lightImpact();

    final success = await LikeService().toggleLike(postId);

    if (!success) {
      setState(() {
        _likedPosts[postId] = currentLiked;
        _likeCounts[postId] =
            (_likeCounts[postId] ?? 0) + (currentLiked ? 1 : -1);
      });
    }
  }

  // ✅ Load likes untuk related posts
  Future<void> _loadLikesForRelatedPosts(
    List<Map<String, dynamic>> posts,
  ) async {
    final currentUserId = await SecureStorage.getUserId();
    await Future.wait(
      posts.map((post) async {
        final postId = post['post_id'] as int;
        try {
          final likes = await LikeService().getLikes(postId);
          _likeCounts[postId] = likes.length;
          _likedPosts[postId] = likes.any(
            (like) => like['user_id'] == currentUserId,
          );
        } catch (e) {
          print("Error loading likes for post $postId: $e");
          _likeCounts[postId] = 0;
          _likedPosts[postId] = false;
        }
      }),
    );
    setState(() {});
  }

  Future<Map<String, int>> getPostStats(int postId) async {
    try {
      final likesResponse = await http.get(
        Uri.parse('https://api.portalsi.com/api/posts/$postId/likes'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      final commentsResponse = await http.get(
        Uri.parse('https://api.portalsi.com/api/posts/$postId/comments'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      int likesCount = 0;
      int commentsCount = 0;

      if (likesResponse.statusCode == 200) {
        final likesData = json.decode(likesResponse.body);
        if (likesData is List) {
          likesCount = likesData.length;
        } else if (likesData is Map && likesData['count'] != null) {
          likesCount = likesData['count'];
        }
      }

      if (commentsResponse.statusCode == 200) {
        final commentsData = json.decode(commentsResponse.body);
        if (commentsData is List) {
          commentsCount = commentsData.length;
        } else if (commentsData is Map && commentsData['count'] != null) {
          commentsCount = commentsData['count'];
        }
      }

      return {'likes': likesCount, 'comments': commentsCount};
    } catch (e) {
      debugPrint('Error getting post stats: $e');
      return {'likes': 0, 'comments': 0};
    }
  }

  final List<String> _apiEndpoints = ['https://api.portalsi.com/api/posts'];

  Map<String, dynamic> _enhancePostWithStats(Map<String, dynamic> post) {
    return {
      ...post,
      'likes_count': post['likes_count'] ?? 0,
      'comments_count': post['comments_count'] ?? 0,
      'caption': post['caption'] ?? '',
      'media_url': post['media_url'] ?? '',
      'created_at': post['created_at'] ?? DateTime.now().toIso8601String(),
      'user': post['user'] ??
          {
            'username': 'Unknown',
            'profile_picture_url': '',
            'is_verified': false,
          },
    };
  }

  Future<void> _fetchRelatedPosts() async {
    try {
      setState(() {
        _isLoadingRelated = true;
      });

      Exception? lastException;

      for (String endpoint in _apiEndpoints) {
        try {
          debugPrint('Trying endpoint: $endpoint');

          final authToken = await SecureStorage.getToken();

          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Flutter App',
              'Authorization': 'Bearer $authToken',
            },
          ).timeout(const Duration(seconds: 10));

          debugPrint('Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final dynamic responseData = json.decode(response.body);

            List<dynamic> data;
            if (responseData is Map<String, dynamic>) {
              data = responseData['data'] ??
                  responseData['posts'] ??
                  responseData['result'] ??
                  [];
            } else if (responseData is List) {
              data = responseData;
            } else {
              debugPrint(
                'Unexpected response format: ${responseData.runtimeType}',
              );
              continue;
            }

            if (data.isEmpty) {
              debugPrint('No posts found in response from $endpoint');
              continue;
            }

            final List<Map<String, dynamic>> allFetchedPosts = data
                .where((item) => item is Map<String, dynamic>)
                .cast<Map<String, dynamic>>()
                .toList();

            debugPrint(
              "Total posts fetched from $endpoint: ${allFetchedPosts.length}",
            );

            final filteredPosts = allFetchedPosts
                .where(
                  (post) =>
                      post['post_id'] != null &&
                      post['post_id'] != widget.postId &&
                      post['user'] != null &&
                      post['media_url'] != null &&
                      post['media_url'] != '',
                )
                .toList();

            final List<Map<String, dynamic>> enhancedPosts = filteredPosts
                .map((post) => _enhancePostWithStats(post))
                .toList();

            enhancedPosts.shuffle(Random());

            final List<Map<String, dynamic>> randomPosts =
                enhancedPosts.take(10).toList();

            setState(() {
              _relatedPosts = randomPosts;
              _isLoadingRelated = false;
            });

            debugPrint("Success! Final related posts: ${randomPosts.length}");

            // Load likes untuk related posts
            _loadLikesForRelatedPosts(randomPosts);

            return;
          } else if (response.statusCode == 500) {
            debugPrint('Server error 500 from $endpoint, trying next...');
            lastException = Exception('Server sedang bermasalah');
            continue;
          } else {
            debugPrint('HTTP ${response.statusCode} from $endpoint');
            lastException = Exception('HTTP Error ${response.statusCode}');
            continue;
          }
        } catch (e) {
          debugPrint('Error with endpoint $endpoint: $e');
          lastException = Exception(e.toString());
          continue;
        }
      }

      throw lastException ?? Exception('Semua endpoint gagal');
    } catch (e) {
      debugPrint('All endpoints failed: $e');
      setState(() {
        _isLoadingRelated = false;
      });

      if (_relatedPosts.isEmpty && mounted) {
        _showErrorSnackBar('Failed to load related posts');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchRelatedPosts,
        ),
      ),
    );
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
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: _buildModernPreviewDialog(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernPreviewDialog(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.network(
                  item['media_url'] ?? '',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[200]!, Colors.grey[100]!],
                        ),
                      ),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        size: 60,
                      ),
                    );
                  },
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Close dialog first
                          _onRelatedPostProfileTap(item);
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: item['user']?['profile_picture_url']
                                      ?.isNotEmpty ==
                                  true
                              ? NetworkImage(
                                  item['user']['profile_picture_url'])
                              : null,
                          child:
                              item['user']?['profile_picture_url']?.isEmpty !=
                                      false
                                  ? Icon(Icons.person, size: 20)
                                  : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pop(); // Close dialog first
                                    _onRelatedPostProfileTap(item);
                                  },
                                  child: Text(
                                    item['user']?['username'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (item['user']?['is_verified'] == true) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              timeAgoFromDate(item['created_at']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    item['caption'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
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
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _fetchRelatedPosts,
          color: Theme.of(context).primaryColor,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _relatedPosts.length +
                (_relatedPosts.isEmpty && !_isLoadingRelated ? 2 : 3),
            itemBuilder: (context, index) {
              if (index == 0) return _buildModernMainPost();
              if (index == 1) return _buildModernRelatedPostsHeader();
              if (index == _relatedPosts.length + 2)
                return const SizedBox(height: 100);

              // Wrap related post with tap gesture for navigation
              return GestureDetector(
                onTap: () {
                  final post = _relatedPosts[index - 2];
                  final postId = post['post_id'] as int;
                  final likesCount =
                      _likeCounts[postId] ?? post['likes_count'] ?? 0;
                  final isLiked = _likedPosts[postId] ?? false;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailPage(
                        postId: postId,
                        username: post['user']?['username'] ?? 'Unknown',
                        timeAgo: timeAgoFromDate(post['created_at']),
                        imageUrl: post['media_url'] ?? '',
                        content: post['caption'] ?? '',
                        likes: likesCount,
                        comments: post['comments_count'] ?? 0,
                        profileImageUrl:
                            post['user']?['profile_picture_url'] ?? '',
                        isVerified: post['user']?['is_verified'] ?? false,
                        isLiked: isLiked,
                        userId: post['user']?['user_id'] ?? post['user']?['id'],
                        user: post['user'],
                      ),
                    ),
                  );
                },
                onLongPress: () =>
                    _showEnhancedPostPreview(_relatedPosts[index - 2]),
                child: _buildModernRelatedPost(_relatedPosts[index - 2]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernMainPost() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: PostCard(
        postId: widget.postId,
        username: widget.username,
        timeAgo: widget.timeAgo,
        imageUrl: widget.imageUrl,
        content: widget.content,
        likes: _currentPostLikes,
        comments: widget.comments,
        isVerified: widget.isVerified,
        profileImageUrl: widget.profileImageUrl,
        isLiked: _currentPostLiked,
        isBookmarked: false,
        user: {
          'username': widget.username,
          'profile_picture_url': widget.profileImageUrl,
          'is_verified': widget.isVerified,
          'user_id': widget.userId,
        },
        onLike: _onLikeMainPost,
        onBookmark: () {
          debugPrint('Bookmarked main post: ${widget.postId}');
        },
        onShare: () {
          debugPrint('Shared main post: ${widget.postId}');
        },
        onComment: _onCommentMainPost,
        onProfileTap: _onMainPostProfileTap, // ✅ Tambahkan callback
      ),
    );
  }

  Widget _buildModernRelatedPostsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingRelated)
            Center(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            )
          else if (_relatedPosts.isEmpty)
            Center(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 24),
                    SizedBox(height: 8),
                    Text(
                      'No more posts available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _fetchRelatedPosts,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tap to retry',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernRelatedPost(Map<String, dynamic> post) {
    final postId = post['post_id'] as int;
    final likesCount = _likeCounts[postId] ?? post['likes_count'] ?? 0;
    final isLiked = _likedPosts[postId] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: PostCard(
        postId: postId,
        username: post['user']?['username'] ?? 'Unknown User',
        timeAgo: timeAgoFromDate(post['created_at']),
        imageUrl: post['media_url'] ?? '',
        likes: likesCount,
        comments: post['comments_count'] ?? 0,
        content: post['caption'] ?? '',
        isVerified: post['user']?['is_verified'] ?? false,
        isLiked: isLiked,
        isBookmarked: false,
        profileImageUrl: post['user']?['profile_picture_url'] ?? '',
        user: post['user'] ?? {},
        onLike: () => _onLikeRelatedPost(post),
        onBookmark: () {
          debugPrint('Bookmarked post: $postId');
        },
        onShare: () {
          debugPrint('Shared post: $postId');
        },
        onComment: () => _onCommentRelatedPost(post),
        onProfileTap: () =>
            _onRelatedPostProfileTap(post), // ✅ Tambahkan callback
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
        backgroundColor: Color(0xFFF8FAFC),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 0,
          title: const Text(
            'Post Detail',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _fetchRelatedPosts,
                tooltip: 'Refresh related posts',
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildModernBackgroundGradient(),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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

  Widget _buildModernBackgroundGradient() {
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
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ✅ Comment Bottom Sheet Implementation
void showCommentSheet(BuildContext context, int postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                child: CommentSection(
                  scrollController: controller,
                  postId: postId,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

// ✅ Comment Section Widget
class CommentSection extends StatefulWidget {
  final ScrollController? scrollController;
  final int postId;

  const CommentSection({Key? key, this.scrollController, required this.postId})
      : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final int? parentCommentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String username;
  bool liked;
  int likes;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    this.liked = false,
    this.likes = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['comment_id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      parentCommentId: json['parent_comment_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      username: json['username'] ?? 'User',
      likes: json['likes'] ?? 0,
      liked: json['liked'] ?? false,
    );
  }
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();

  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      print("Loading comments for postId: ${widget.postId}");
      final data = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = data.map((e) => Comment.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print('Error loading comments: $e');
      print(stacktrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success =
        await _commentService.sendCommentOptimistic(widget.postId, content);
    if (success) {
      _commentController.clear();
      await _loadComments();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.scrollController?.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleLike(Comment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Komentar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading comments...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada komentar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Jadilah yang pertama berkomentar!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments.reversed.toList()[index];
                          return Column(
                            children: [
                              _buildComment(comment),
                              if (index < _comments.length - 1)
                                Divider(
                                  color: Colors.grey[300],
                                  height: 16,
                                  thickness: 0.5,
                                  indent: 52,
                                ),
                            ],
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[600],
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan komentar...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addComment(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _addComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[600],
            child: Text(
              comment.username[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(comment),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: comment.liked
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.red, Colors.pink],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Icon(Icons.favorite, size: 18),
                        )
                      : Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                ),
              ),
              if (comment.likes > 0)
                Text(
                  comment.likes.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
