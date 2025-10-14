// lib/pages/other_profile_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../app_state.dart';
import '../components/circular_avatar_fetcher.dart';
import '../components/pressable_grid_item.dart';
import '../components/verified_badge.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/navigation_provider.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../utils/navigation_helper.dart';
import 'chat_room.dart';
import 'clips_viewer_page.dart';
import 'followers_following_page.dart';
import 'fullscreen_image_viewer.dart';
import 'portfolio_pages.dart';
import 'post_detail.dart';

// --- WIDGET BIO ---
class _ExpandableBio extends StatefulWidget {
  final String bio;
  const _ExpandableBio({required this.bio});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _isExpanded = false;
  bool _isLongBio = false;

  final int maxChars = 120;
  final int maxLinesThreshold = 3;

  @override
  void initState() {
    super.initState();
    _isLongBio = widget.bio.length > maxChars || widget.bio.split('\n').length > maxLinesThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bio.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (!_isLongBio) {
      return Text(
        widget.bio,
        style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topLeft,
          child: Text(
            widget.bio,
            maxLines: _isExpanded ? null : maxLinesThreshold,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'Tampilkan lebih sedikit' : 'Baca Selengkapnya',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class OtherProfilePage extends StatefulWidget {
  final String username;

  const OtherProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with TickerProviderStateMixin {
  User? _profileData;

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowActionLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ProfileService _profileService = ProfileService();
  final FollowService _followService = FollowService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAvatarPopup(BuildContext context) {
    if (_profileData == null || _profileData!.profilePictureUrl == null) return;

    final String heroTag = 'profile_${_profileData!.username}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          elevation: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Text(
                  _profileData!.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: _profileData!.profilePictureUrl!,
                        heroTag: heroTag,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CachedNetworkImage(
                    imageUrl: _profileData!.profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey[200]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileService.getOtherProfile(widget.username);
      final followStatus =
      await _followService.getFollowStatus(widget.username);

      if (mounted) {
        setState(() {
          _profileData = profile;
          _isFollowing = followStatus['isFollowing'] ?? false;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat profil: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollowAction() async {
    if (_isFollowActionLoading || _profileData == null) return;
    setState(() => _isFollowActionLoading = true);

    try {
      final username = _profileData!.username;
      final originalFollowersCount = _profileData!.followersCount;
      final originalFollowingState = _isFollowing;

      setState(() {
        _isFollowing = !_isFollowing;
        _profileData = _profileData!.copyWith(
          followersCount: originalFollowersCount + (_isFollowing ? 1 : -1),
        );
      });

      bool success = _isFollowing
          ? await _followService.followUser(username)
          : await _followService.unfollowUser(username);

      if (!success && mounted) {
        setState(() {
          _isFollowing = originalFollowingState;
          _profileData =
              _profileData!.copyWith(followersCount: originalFollowersCount);
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          // Re-fetch to be safe or revert manually
          _loadAllData();
        });
      }
    } finally {
      if (mounted) setState(() => _isFollowActionLoading = false);
    }
  }

  void _navigateToFollowersFollowing(int initialTab) async {
    if (_profileData == null || _profileData!.id == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: _profileData!.id!,
          username: _profileData!.username,
          initialTab: initialTab,
        ),
      ),
    );

    if (result != null && mounted) {
      final userToNavigate = User.fromJson(result);
      NavigationHelper.navigateToProfile(
        context,
        userToNavigate,
      );
    }
  }

  void _navigateToChatRoom() {
    if (_profileData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(user: _profileData!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildOtherProfileAppBar(User? user) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
              },
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    user?.username ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (user?.isVerified ?? false)
                  const VerifiedBadge(size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    Widget screenContent;

    if (_isLoading) {
      screenContent = const ProfilePageSkeleton();
    } else if (_error != null) {
      screenContent = Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              ElevatedButton(
                  onPressed: _loadAllData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    } else {
      screenContent = FadeTransition(
        opacity: _animationController,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildOtherProfileAppBar(_profileData),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.orange,
                  // Mengatur warna latar belakang lingkaran
                  backgroundColor: Colors.orange.shade50,
                  onRefresh: _loadAllData,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCoverImage(),
                        _buildProfileCard(),
                        _buildPostGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
        }
      },
      child: screenContent,
    );
  }

  Widget _buildCoverImage() {
    final imageUrl = _profileData?.bannerUrl?.isNotEmpty == true
        ? _profileData!.bannerUrl!
        : (_profileData?.profilePictureUrl?.isNotEmpty == true
        ? _profileData!.profilePictureUrl!
        : 'https://via.placeholder.com/400');

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(color: Colors.white)),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Transform.translate(
      offset: const Offset(0, -45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 45),
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: _buildProfileInfo(),
              ),
            ),
            Positioned(
              top: 0,
              left: 24,
              child: GestureDetector(
                onLongPress: () {
                  HapticFeedback.vibrate();
                  _showAvatarPopup(context);
                },
                child: Hero(
                  tag: 'profile_${_profileData!.username}',
                  child: CircularAvatarFetcher(
                    radius: 45,
                    userId: _profileData!.id ?? 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _profileData!.fullName ?? _profileData!.username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ExpandableBio(bio: _profileData?.bio ?? ''),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildStatText(_profileData!.postsCount.toString(), 'postingan'),
            const SizedBox(width: 24),
            _buildStatText(_profileData!.followersCount.toString(), 'pengikut',
                onTap: () => _navigateToFollowersFollowing(0)),
            const SizedBox(width: 24),
            _buildStatText(_profileData!.followingCount.toString(), 'mengikuti',
                onTap: () => _navigateToFollowersFollowing(1)),
          ],
        ),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isFollowActionLoading ? null : _handleFollowAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[200] : const Color(0xFFF58723),
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  elevation: _isFollowing ? 0 : 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isFollowActionLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _navigateToChatRoom,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Kirim Pesan',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10,),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: const Color(0x83B98946), offset: const Offset(0, 3), blurRadius: 10, spreadRadius: -2),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_profileData != null) {
                      Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: PortfolioPage(user: _profileData!)));
                      HapticFeedback.lightImpact();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC87B),
                    foregroundColor: Colors.grey[800],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lihat Portofolio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatText(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 15),
          children: [
            TextSpan(
              text: count,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' $label',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // --- 👇 PERBAIKAN UTAMA DI SINI 👇 ---
  Widget _buildPostGrid() {
    if (_profileData == null || _profileData!.recentPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.only(top: 80),
        alignment: Alignment.center,
        child: const Text('Belum ada postingan'),
      );
    }

    final posts = _profileData!.recentPosts;
    const int columnCount = 3;

    return Container(
      margin: const EdgeInsets.only(top: 24.0),
      padding: const EdgeInsets.only(bottom: 80.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: AnimationLimiter(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: posts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final post = posts[index];

              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 400),
                columnCount: columnCount,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: PressableGridItem(
                      key: ValueKey(post.postId),
                      post: post,
                      user: _profileData!,
                      onTap: () {
                        final navProvider = Provider.of<NavigationProvider>(context, listen: false);

                        if (post.isVideo) {
                          final fullPostObject = Post.fromJson({
                            'id': post.postId,
                            'caption': post.caption,
                            'media_url': post.mediaUrl,
                            'is_video': post.isVideo,
                            'created_at': post.createdAt.toIso8601String(),
                            'user': _profileData!.toJson(),
                            // Pastikan API mengirim data ini atau beri nilai default
                            'is_liked_by_user': post.isLikedByUser,
                            'is_bookmarked': post.isBookmarked,
                          });
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ClipsViewerPage(initialClip: fullPostObject)));
                        } else {
                          navProvider.replaceOverlay(PostDetail(postId: post.postId));
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: Colors.white,
            height: 60 + MediaQuery.of(context).padding.top,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    height: 160,
                    color: Colors.white,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -45),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatSkeleton(),
                                      _buildStatSkeleton(),
                                      _buildStatSkeleton(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildLineSkeleton(height: 22, width: 200),
                          const SizedBox(height: 16),
                          _buildLineSkeleton(height: 15),
                          const SizedBox(height: 8),
                          _buildLineSkeleton(height: 15, width: 250),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildLineSkeleton(height: 48, radius: 10)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildLineSkeleton(height: 48, radius: 10)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildLineSkeleton(height: 48, radius: 10),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(6, (index) => _buildGridItemSkeleton()),
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

  Widget _buildGridItemSkeleton() {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        _buildLineSkeleton(width: 35, height: 16, radius: 4),
        const SizedBox(height: 8),
        _buildLineSkeleton(width: 50, height: 12, radius: 4),
      ],
    );
  }

  Widget _buildLineSkeleton(
      {double? width, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
