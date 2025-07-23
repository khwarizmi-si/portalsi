import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/utils/secure_storage.dart';
import '../components/post_card.dart';
import 'dashboard_page.dart';
import '../components/bottom_navigation.dart';
import '../helper/time_helper.dart';
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
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _relatedPosts = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchRelatedPosts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  // Function to get additional post stats (likes, comments)
  Future<Map<String, int>> getPostStats(int postId) async {
    try {
      // Try to get likes count
      final likesResponse = await http
          .get(
            Uri.parse('https://api.portalsi.com/api/posts/$postId/likes'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      // Try to get comments count
      final commentsResponse = await http
          .get(
            Uri.parse('https://api.portalsi.com/api/posts/$postId/comments'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

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

  final List<String> _apiEndpoints = [
    'https://api.portalsi.com/api/posts',
    // Alternative endpoint
    // Add more fallback endpoints if available
  ];

  // Load stats for posts asynchronously
  Future<void> _loadPostsStats(List<Map<String, dynamic>> posts) async {
    for (int i = 0; i < posts.length; i++) {
      try {
        final stats = await getPostStats(posts[i]['post_id']);
        if (mounted) {
          setState(() {
            _relatedPosts[i]['likes_count'] = stats['likes'];
            _relatedPosts[i]['comments_count'] = stats['comments'];
          });
        }
      } catch (e) {
        debugPrint('Error loading stats for post ${posts[i]['post_id']}: $e');
      }

      // Add small delay to prevent overwhelming the server
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Map<String, dynamic> _enhancePostWithStats(Map<String, dynamic> post) {
    return {
      ...post,
      'likes_count': post['likes_count'] ?? 0,
      'comments_count': post['comments_count'] ?? 0,
      'caption': post['caption'] ?? '',
      'media_url': post['media_url'] ?? '',
      'created_at': post['created_at'] ?? DateTime.now().toIso8601String(),
      'user':
          post['user'] ??
          {
            'username': 'Unknown',
            'profile_picture_url': '',
            'is_verified': false,
          },
    };
  }

  Future<void> fetchRelatedPosts() async {
    try {
      setState(() {
        _isLoadingRelated = true;
      });

      Exception? lastException;

      // Try each endpoint until one works
      for (String endpoint in _apiEndpoints) {
        try {
          debugPrint('Trying endpoint: $endpoint');

          final authToken =
              await SecureStorage.getToken(); // Contoh ambil token

          final response = await http
              .get(
                Uri.parse(endpoint),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'User-Agent': 'Flutter App',
                  'Authorization': 'Bearer $authToken',
                },
              )
              .timeout(const Duration(seconds: 10));

          debugPrint('Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final dynamic responseData = json.decode(response.body);

            // Handle different response formats
            List<dynamic> data;
            if (responseData is Map<String, dynamic>) {
              // If response is wrapped in an object
              data =
                  responseData['data'] ??
                  responseData['posts'] ??
                  responseData['result'] ??
                  [];
            } else if (responseData is List) {
              // If response is direct array
              data = responseData;
            } else {
              debugPrint(
                'Unexpected response format: ${responseData.runtimeType}',
              );
              continue; // Try next endpoint
            }

            if (data.isEmpty) {
              debugPrint('No posts found in response from $endpoint');
              continue; // Try next endpoint
            }

            final List<Map<String, dynamic>> allFetchedPosts = data
                .where((item) => item is Map<String, dynamic>)
                .cast<Map<String, dynamic>>()
                .toList();

            debugPrint(
              "Total posts fetched from $endpoint: ${allFetchedPosts.length}",
            );
            debugPrint("Post utama: ${widget.postId}");

            // Filter post agar tidak termasuk post yang sedang dibuka
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

            // Enhance posts with default stats
            final List<Map<String, dynamic>> enhancedPosts = filteredPosts
                .map((post) => _enhancePostWithStats(post))
                .toList();

            debugPrint("Filtered posts: ${enhancedPosts.length}");

            // Shuffle untuk randomisasi
            enhancedPosts.shuffle(Random());

            // Ambil maksimal 10 postingan secara acak
            final List<Map<String, dynamic>> randomPosts = enhancedPosts
                .take(10)
                .toList();

            setState(() {
              _relatedPosts = randomPosts;
              _isLoadingRelated = false;
            });

            debugPrint("Success! Final related posts: ${randomPosts.length}");

            // Optionally load stats for each post asynchronously
            _loadPostsStats(randomPosts);

            return; // Success, exit the function
          } else if (response.statusCode == 500) {
            debugPrint('Server error 500 from $endpoint, trying next...');
            lastException = Exception('Server sedang bermasalah');
            continue; // Try next endpoint
          } else {
            debugPrint('HTTP ${response.statusCode} from $endpoint');
            lastException = Exception('HTTP Error ${response.statusCode}');
            continue; // Try next endpoint
          }
        } catch (e) {
          debugPrint('Error with endpoint $endpoint: $e');
          lastException = Exception(e.toString());
          continue; // Try next endpoint
        }
      }

      // If we reach here, all endpoints failed
      throw lastException ?? Exception('Semua endpoint gagal');
    } catch (e) {
      debugPrint('All endpoints failed: $e');
      setState(() {
        _isLoadingRelated = false;
      });

      // Only show error if there are no existing posts
      if (_relatedPosts.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Exception:')
                  ? e.toString().replaceFirst('Exception: ', '')
                  : 'Tidak dapat memuat postingan terkait',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: fetchRelatedPosts,
            ),
          ),
        );
      }
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
                  item['media_url'] ?? '',
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 280,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
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
                    item['user']?['username'] ?? 'Unknown User',
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
                    maxLines: 3,
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
      child: RefreshIndicator(
        onRefresh: fetchRelatedPosts,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount:
              _relatedPosts.length +
              (_relatedPosts.isEmpty && !_isLoadingRelated
                  ? 2
                  : 3), // Dynamic count
          itemBuilder: (context, index) {
            if (index == 0) return _buildMainPost();
            if (index == 1) return _buildRelatedPostsHeader();
            if (index == _relatedPosts.length + 2)
              return const SizedBox(height: 100);
            return _buildRelatedPost(_relatedPosts[index - 2]);
          },
        ),
      ),
    );
  }

  Widget _buildMainPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
        user: {},
        onLike: () {},
        onBookmark: () {},
        onShare: () {},
        onComment: () {},
      ),
    );
  }

  Widget _buildRelatedPostsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Postingan Lainnya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (_isLoadingRelated)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_relatedPosts.isEmpty)
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            ],
          ),
          if (_relatedPosts.isEmpty && !_isLoadingRelated)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak ada postingan lain yang tersedia',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: fetchRelatedPosts,
                    child: Text(
                      'Tap untuk mencoba lagi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedPost(Map<String, dynamic> post) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to detail of this post
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                postId: post['post_id'] ?? 0,
                username: post['user']?['username'] ?? 'Unknown',
                timeAgo: timeAgoFromDate(post['created_at']),
                imageUrl: post['media_url'] ?? '',
                content: post['caption'] ?? '',
                likes: post['likes_count'] ?? 0,
                comments: post['comments_count'] ?? 0,
                profileImageUrl: post['user']?['profile_picture_url'] ?? '',
                isVerified: post['user']?['is_verified'] ?? false,
              ),
            ),
          );
        },
        onLongPress: () => _showEnhancedPostPreview(post),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.7),
          ),
          child: PostCard(
            postId: post['post_id'] ?? 0,
            username: post['user']?['username'] ?? 'Unknown User',
            timeAgo: timeAgoFromDate(post['created_at']),
            imageUrl: post['media_url'] ?? '',
            likes: post['likes_count'] ?? 0,
            comments: post['comments_count'] ?? 0,
            content: post['caption'] ?? '',
            isVerified: post['user']?['is_verified'] ?? false,
            isLiked: false, // Default karena API tidak ada field ini
            isBookmarked: false, // Default karena API tidak ada field ini
            profileImageUrl: post['user']?['profile_picture_url'] ?? '',
            user: post['user'] ?? {},
            onLike: () {
              // Implement like functionality
              debugPrint('Liked post: ${post['post_id']}');
            },
            onBookmark: () {
              // Implement bookmark functionality
              debugPrint('Bookmarked post: ${post['post_id']}');
            },
            onShare: () {
              // Implement share functionality
              debugPrint('Shared post: ${post['post_id']}');
            },
            onComment: () {
              // Implement comment functionality
              debugPrint('Comment on post: ${post['post_id']}');
            },
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchRelatedPosts,
              tooltip: 'Refresh postingan terkait',
            ),
          ],
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
