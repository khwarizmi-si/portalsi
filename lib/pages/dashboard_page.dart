// lib/pages/dashboard_page.dart
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

// Halaman & Komponen UI
import 'package:portal_si/components/post_card.dart';
import 'package:portal_si/components/story_section.dart';
import 'package:portal_si/widgets/comment_section.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/pages/message_list_page.dart';
import 'package:portal_si/pages/announcement_list_page.dart';

// State Management & Model
import '../controllers/home_controller.dart';
import '../services/follow_service.dart';
import '../utils/user_provider.dart';
import '../models/post_model.dart';
import '../models/announcement_model.dart';
import '../models/story_model.dart';

// Servis & Helper
import '../services/notification_service.dart';
import '../utils/navigation_helper.dart';
import '../helper/time_helper.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _HomePageState();
}

class _HomePageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin{
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _unreadNotificationCount = 0;
  final GlobalKey _notificationIconKey = GlobalKey();
  final GlobalKey _anncIconKey = GlobalKey();
  final GlobalKey _msgIconKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final isScrolled = _scrollController.offset > 10;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
      Provider.of<HomeController>(context, listen: false).loadDashboardData();
    });
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService().getNotifications();
      final unreadCount = notifications
          .where((notif) => notif['is_read'] == false || notif['is_read'] == 0)
          .length;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notification count in HomePage: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCommentSheet(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: CommentSection(postId: postId),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Penting untuk AutomaticKeepAliveClientMixin

    // 1. Hapus Scaffold, bungkus dengan Material
    return Material(
      color: Colors.transparent, // Agar background terlihat
      child: Stack(
        children: [
          // Konten utama
          SafeArea(
            child: Column(
              children: [
                // 2. AppBar sekarang menjadi widget biasa
                _buildAppBar(context),

                // 3. Pastikan body di-wrap dengan Expanded
                Expanded(
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final bool isAdmin = userProvider.currentUser?.isVerified == true;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              // boxShadow: _isScrolled ? [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.05),
              //     blurRadius: 10,
              //     offset: const Offset(0, 2),
              //   ),
              // ] : [],
            ),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('Portal SI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
              actions: [
                if (isAdmin)
                  IconButton(
                    key: _anncIconKey,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final RenderBox renderBox = _anncIconKey.currentContext!.findRenderObject() as RenderBox;
                      final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                      Navigator.push(context, ScaleFromPositionRoute(widget: const AnnouncementListPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
                    },
                    icon: const Icon(Icons.campaign_outlined, color: Colors.black),
                    tooltip: 'List Pengumuman',
                  ),
                Stack(
                  children: [
                    IconButton(
                      key: _notificationIconKey,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final RenderBox renderBox = _notificationIconKey.currentContext!.findRenderObject() as RenderBox;
                        final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                        Navigator.push(context, ScaleFromPositionRoute(widget: const NotificationPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
                      },
                      icon: const Icon(Icons.notifications, color: Colors.black),
                      tooltip: 'Notifikasi',
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(_unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  key: _msgIconKey,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final RenderBox renderBox = _msgIconKey.currentContext!.findRenderObject() as RenderBox;
                    final originOffset = renderBox.localToGlobal(Offset.zero) + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
                    Navigator.push(context, ScaleFromPositionRoute(widget: const MessageListPage(), originOffset: originOffset)).then((_) => _loadNotificationCount());
                  },
                  icon: const Icon(Icons.send_outlined, color: Colors.black),
                  tooltip: 'Pesan',
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // --- 👇 PERUBAHAN DI SINI: Cek controller.feedItems ---
        if (controller.isLoading && controller.feedItems.isEmpty) {

          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage != null) {
          return Center(child: Text('Error: ${controller.errorMessage}'));
        }
        if (controller.feedItems.isEmpty && controller.pinnedPost == null && controller.pinnedAnnouncements.isEmpty) {

          return RefreshIndicator(
            onRefresh: () => controller.refreshDashboardData(),
            child: const CustomScrollView(
              slivers: [
                SliverFillRemaining(child: Center(child: Text('Tidak ada konten untuk ditampilkan.')))
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshDashboardData(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: StorySection(stories: controller.stories)),
              SliverToBoxAdapter(child: PinnedAnnouncementsSection(announcements: controller.pinnedAnnouncements)),
              _buildPinnedPost(context, controller),
              SliverList(
                // --- 👇 PERUBAHAN UTAMA DI SINI ---
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final dynamic item = controller.feedItems[index];
                    final String itemType = item is Map ? item['type'] ?? '' : '';

                    if (itemType == 'post') {
                      final Post post = Post.fromJson(item as Map<String, dynamic>);
                      return PostCard(
                        username: post.user.username,
                        timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
                        mediaUrl: post.mediaUrl ?? '',
                        isVideo: post.isVideo,
                        comments: post.commentsCount,
                        content: post.caption ?? '',
                        isVerified: post.user.isVerified,
                        isBookmarked: false,
                        profileImageUrl: post.user.profilePictureUrl ?? '',
                        user: post.user.toJson(),
                        likes: post.likesCount,
                        isLiked: post.isLikedByUser,
                        onLike: () => controller.toggleLike(post.id),
                        onBookmark: () {},
                        onShare: () {},
                        onComment: () => _showCommentSheet(context, post.id),
                        postId: post.id,
                        onProfileTap: () => NavigationHelper.navigateToProfile(context, post.user.toJson()),
                      );
                    } else if (itemType == 'suggestion') {
                      final List<dynamic> users = item['users'] ?? [];
                      return SuggestionCard(users: users);
                    } else {
                      // Return widget kosong jika tipe tidak dikenali
                      return const SizedBox.shrink();
                    }
                  },
                  // Gunakan panjang dari feedItems
                  childCount: controller.feedItems.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinnedPost(BuildContext context, HomeController controller) {
    final pinnedPost = controller.pinnedPost;
    if (pinnedPost == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final bool isExpired = DateTime.now().difference(pinnedPost.createdAt).inHours >= 24;
    if (isExpired) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: _PinnedPostCard(
        post: pinnedPost,
        controller: controller,
        onComment: () => _showCommentSheet(context, pinnedPost.id),
      ),
    );
  }
}

class PinnedAnnouncementsSection extends StatefulWidget {
  final List<Announcement> announcements;
  const PinnedAnnouncementsSection({super.key, required this.announcements});

  @override
  State<PinnedAnnouncementsSection> createState() => _PinnedAnnouncementsSectionState();
}

class _PinnedAnnouncementsSectionState extends State<PinnedAnnouncementsSection> {
  int _currentIndex = 0;
  bool _isSwipingForward = true;
  Timer? _timer;
  bool _isCardExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcements.isNotEmpty) {
      _handleTimer(widget.announcements.length);
    }
  }

  @override
  void didUpdateWidget(covariant PinnedAnnouncementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.announcements.isNotEmpty) {
      _handleTimer(widget.announcements.length);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTimer(int total) {
    _timer?.cancel();
    if (_isCardExpanded || total <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) _swipe(total, forward: true, fromAutoSwipe: true);
    });
  }

  void _swipe(int total, {required bool forward, bool fromAutoSwipe = false}) {
    setState(() {
      _isSwipingForward = forward;
      _currentIndex = (forward ? _currentIndex + 1 : _currentIndex - 1 + total) % total;
    });
    if (!fromAutoSwipe) _handleTimer(total);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final announcements = widget.announcements;
    final totalAnnouncements = announcements.length;
    if (_currentIndex >= totalAnnouncements) _currentIndex = 0;
    final currentAnnouncement = announcements[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (totalAnnouncements <= 1) return;
              if (details.primaryVelocity! < -100) _swipe(totalAnnouncements, forward: true);
              else if (details.primaryVelocity! > 100) _swipe(totalAnnouncements, forward: false);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(_isSwipingForward ? 1.0 : -1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(child: SlideTransition(position: offsetAnimation, child: child));
              },
              child: AnnouncementCard(
                key: ValueKey<int>(currentAnnouncement.id),
                announcement: currentAnnouncement,
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    _isCardExpanded = isExpanded;
                  });
                  _handleTimer(totalAnnouncements);
                },
              ),
            ),
          ),
          if (totalAnnouncements > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${_currentIndex + 1} dari $totalAnnouncements pengumuman',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            )
        ],
      ),
    );
  }
}

class _PinnedPostCard extends StatelessWidget {
  final Post post;
  final HomeController controller;
  final VoidCallback onComment;

  const _PinnedPostCard({required this.post, required this.controller, required this.onComment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.yellow.shade50, Colors.amber.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.push_pin, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Text("Postingan Disematkan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: PostCard(
              username: post.user.username,
              timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
              mediaUrl: post.mediaUrl ?? '',
              isVideo: post.isVideo,
              likes: post.likesCount,
              comments: post.commentsCount,
              content: post.caption ?? '',
              isVerified: post.user.isVerified,
              isLiked: post.isLikedByUser,
              isBookmarked: false,
              profileImageUrl: post.user.profilePictureUrl ?? '',
              user: post.user.toJson(),
              onLike: () => controller.toggleLike(post.id),
              onBookmark: () {},
              onShare: () {},
              onComment: onComment,
              postId: post.id,
              onProfileTap: () => NavigationHelper.navigateToProfile(context, post.user.toJson()),
              hasCardDecoration: false,
            ),
          ),
        ],
      ),
    );
  }
}

class ScaleFromPositionRoute extends PageRouteBuilder {
  final Widget widget;
  final Offset originOffset;

  ScaleFromPositionRoute({required this.widget, required this.originOffset})
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    opaque: false,
    barrierDismissible: true,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final screenSize = MediaQuery.of(context).size;
      final alignX = (originOffset.dx / screenSize.width) * 2 - 1;
      final alignY = (originOffset.dy / screenSize.height) * 2 - 1;
      final curveAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return ScaleTransition(alignment: Alignment(alignX, alignY), scale: curveAnimation, child: child);
    },
  );
}

// --- 👇 KELAS ANNOUNCEMENTCARD DENGAN FUNGSI EXPAND ---
class AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final Function(bool) onExpansionChanged;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onExpansionChanged,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleExpand,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF5D6),
              const Color(0xFFFFE7A3).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: widget.announcement.creator.profilePictureUrl != null
                      ? CachedNetworkImageProvider(widget.announcement.creator.profilePictureUrl!)
                      : null,
                  child: widget.announcement.creator.profilePictureUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign_outlined, color: Colors.orange.shade800, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            timeago.format(widget.announcement.createdAt, locale: 'id'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.announcement.creator.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.announcement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _isExpanded ? double.infinity : 0),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.announcement.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.announcement.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                      Text(
                        widget.announcement.content,
                        style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                      ),
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
}

class SuggestionCard extends StatelessWidget {
  final List<dynamic> users;
  const SuggestionCard({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada user, sembunyikan seluruh bagian
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 230,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Mungkin Anda Kenal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                if (user is! Map<String, dynamic> || user['user_id'] == null) {
                  return const SizedBox.shrink();
                }

                // Setiap kartu sekarang mengelola statenya sendiri
                return _SuggestionProfileCard(
                  key: ValueKey(user['user_id']),
                  user: user,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionProfileCard extends StatefulWidget {
  final Map<String, dynamic> user;

  const _SuggestionProfileCard({super.key, required this.user});

  @override
  State<_SuggestionProfileCard> createState() => _SuggestionProfileCardState();
}

class _SuggestionProfileCardState extends State<_SuggestionProfileCard> {
  bool _isLoading = false;
  bool _isFollowed = false;
  bool _showShimmer = false;

  final FollowService _followService = FollowService();

  // --- ⬇️ PERUBAHAN UTAMA: FUNGSI INI SEKARANG MENGATUR FOLLOW & UNFOLLOW ⬇️ ---
  Future<void> _toggleFollowStatus() async {
    setState(() => _isLoading = true);

    bool success;

    // Jika sudah mengikuti, jalankan unfollow. Jika belum, jalankan follow.
    if (_isFollowed) {
      success = await _followService.unfollowUser(widget.user['user_id']);
    } else {
      success = await _followService.followUser(widget.user['user_id']);
    }

    if (!mounted) return;

    if (success) {
      // Perbarui state berdasarkan aksi yang berhasil
      setState(() {
        _isFollowed = !_isFollowed; // Balikkan status follow
      });

      // Hanya tampilkan shimmer saat follow, bukan saat unfollow
      if (_isFollowed) {
        setState(() => _showShimmer = true);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _showShimmer = false);
          }
        });
      }
    } else {
      // Tampilkan pesan error jika aksi gagal
      final action = _isFollowed ? "berhenti mengikuti" : "mengikuti";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal $action ${widget.user['username']}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }

    // Selesaikan loading setelah semua proses selesai
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profilePic = widget.user['profile_picture_url'] ?? '';
    final username = widget.user['username'] ?? 'No Username';
    final fullName = widget.user['full_name'] ?? 'No Name';
    final bool isFollowBack = widget.user['is_follow_back'] ?? false;
    final String buttonText = _isFollowed ? 'Mengikuti' : (isFollowBack ? 'Ikuti Balik' : 'Ikuti');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          // LAPISAN 1: KONTEN KARTU
          InkWell(
            onTap: () => NavigationHelper.navigateToProfile(context, widget.user),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profilePic.isNotEmpty ? CachedNetworkImageProvider(profilePic) : null,
                    child: profilePic.isEmpty ? const Icon(Icons.person, size: 30) : null,
                  ),
                  const SizedBox(height: 8),
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(fullName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  ElevatedButton(
                    // Panggil fungsi toggle yang baru
                    onPressed: _isLoading ? null : _toggleFollowStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowed ? Colors.grey.shade300 : Colors.blue,
                      foregroundColor: _isFollowed ? Colors.black54 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(88, 36),
                      elevation: _isFollowed ? 0 : 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(buttonText),
                  ),
                ],
              ),
            ),
          ),

          // LAPISAN 2: EFEK KILAU (SHIMMER)
          if (_showShimmer)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.6),
                  period: const Duration(milliseconds: 1000),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}