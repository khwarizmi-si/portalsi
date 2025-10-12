import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:portal_si/pages/story_view_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../components/video_thumbnail_widget.dart';
import '../app_state.dart';
import '../components/circular_avatar_fetcher.dart';
import '../components/verified_badge.dart';
// --- IMPORT TAMBAHAN YANG DIBUTUHKAN ---
import '../utils/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/scroll_provider.dart';
import '../services/follow_service.dart';
import '../services/story_service.dart';
import '../utils/navigation_helper.dart';
import 'clips_viewer_page.dart';
import 'create_story_page.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'post_detail.dart';
import 'settings_page.dart';
import 'share_profile_page.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../utils/zoom_page_route.dart';
import 'package:palette_generator/palette_generator.dart';


// --- WIDGET BARU UNTUK SHIMMER PLACEHOLDER ---
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }
}

class PostPopupContent extends StatefulWidget {
  final SimplePost post;
  final User user;
  final Function(SimplePost) onDelete;

  const PostPopupContent({
    Key? key,
    required this.post,
    required this.user,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<PostPopupContent> createState() => _PostPopupContentState();
}

class _PostPopupContentState extends State<PostPopupContent> {
  Color _iconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _updateIconColor();
  }

  Future<void> _updateIconColor() async {
    try {
      final imageProvider = CachedNetworkImageProvider(widget.post.mediaUrl);
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
        maximumColorCount: 20,
      );
      final Color dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      final double luminance = dominantColor.computeLuminance();
      if (mounted) {
        setState(() {
          _iconColor = luminance > 0.4 ? Colors.black87 : Colors.white;
        });
      }
    } catch (e) {
      print("Error saat menganalisis warna gambar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.user.profilePictureUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ImagePlaceholder(),
                      errorWidget: (context, url, error) => const CircleAvatar(backgroundColor: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.user.username,
                  style: TextStyle(color: _iconColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: _iconColor),
                  onSelected: (String value) {
                    Navigator.of(context).pop();
                    if (value == 'delete') {
                      widget.onDelete(widget.post);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Postingan')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: 'post-hero-${widget.post.postId}',
                child: CachedNetworkImage(
                  imageUrl: widget.post.mediaUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const AspectRatio(
                    aspectRatio: 1,
                    child: ImagePlaceholder(),
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

class TransientPostPreview extends StatelessWidget {
  final SimplePost post;
  final User user;

  const TransientPostPreview({
    Key? key,
    required this.post,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.white;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.profilePictureUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ImagePlaceholder(),
                        errorWidget: (context, url, error) => const CircleAvatar(backgroundColor: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: 'post-hero-${post.postId}',
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const AspectRatio(
                    aspectRatio: 1,
                    child: ImagePlaceholder(),
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

class PressableGridItem extends StatefulWidget {
  final SimplePost post;
  final User user;
  final VoidCallback onTap;

  const PressableGridItem({
    Key? key,
    required this.post,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PressableGridItem> createState() => _PressableGridItemState();
}

class _PressableGridItemState extends State<PressableGridItem> {
  bool _isPressed = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removePreviewOverlay();
    super.dispose();
  }

  void _showPreviewOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Center(
              child: TransientPostPreview(
                post: widget.post,
                user: widget.user,
              ),
            ),
          ],
        );
      },
    );

    overlayState?.insert(_overlayEntry!);
  }

  void _removePreviewOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTapDown(TapDownDetails details) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }
  void _onTapCancel() {
    if(mounted){
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mediaDisplay;
    if (widget.post.isVideo) {
      mediaDisplay = VideoThumbnailWidget(videoUrl: widget.post.mediaUrl);
    } else {
      mediaDisplay = CachedNetworkImage(
        imageUrl: widget.post.mediaUrl,
        fit: BoxFit.cover,
        // SEMULA: Hanya Container berwarna abu-abu
        // placeholder: (context, url) => Container(color: Colors.grey[200]),

        // SESUDAH: Menggunakan Shimmer effect yang lebih menarik
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey,)),
        placeholder: (context, url) => const ImagePlaceholder(),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: () => _showPreviewOverlay(context),
      onLongPressUp: () => _removePreviewOverlay(),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(40.0),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.post.isVideo)
                mediaDisplay
              else
                Hero(
                  tag: 'post-hero-${widget.post.postId}',
                  child: mediaDisplay,
                ),
              if (widget.post.isVideo)
                const Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Icon(
                    Icons.video_camera_back_rounded,
                    color: Colors.white,
                    size: 22.0,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class HeroDialogRoute<T> extends PageRoute<T> {
  HeroDialogRoute({required this.builder}) : super();
  final WidgetBuilder builder;
  @override bool get opaque => false;
  @override bool get barrierDismissible => true;
  @override Duration get transitionDuration => const Duration(milliseconds: 350);
  @override bool get maintainState => true;
  @override Color get barrierColor => Colors.black.withOpacity(0.6);
  @override String get barrierLabel => 'Popup';
  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  final ProfileService _profileService = ProfileService();
  late Future<User> _userFuture;
  late Future<List<dynamic>> _suggestionsFuture;
  final GlobalKey _menuKey = GlobalKey();
  late ScrollController _scrollController;
  final StoryService _storyService = StoryService();
  bool _showSuggestions = true;
  Key _avatarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
      final direction = _scrollController.position.userScrollDirection;

      if (direction == ScrollDirection.reverse) {
        scrollProvider.setScrolled(true);
      }
      else if (direction == ScrollDirection.forward) {
        scrollProvider.setScrolled(false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _userFuture = _profileService.getProfile();
      _suggestionsFuture = _profileService.fetchSuggestions();
    });
  }

  Future<void> _navigateToCreateStory(User user) async {
    final heroTag = 'story_create_avatar_${user.id}';
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CreateStoryPage(
          currentUser: user,
          heroTag: heroTag,
          initialImageUrl: user.profilePictureUrl,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (result == true && mounted) {
      await _handleRefresh();
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? existingRole = userProvider.currentUser?.role;

      final User newlyFetchedUser = await _profileService.refreshProfile();

      final User correctedUser = newlyFetchedUser.copyWith(role: existingRole);

      if (mounted) {
        await userProvider.updateCurrentUser(correctedUser);
      }

      setState(() {
        _userFuture = Future.value(correctedUser);
        _suggestionsFuture = _profileService.fetchSuggestions();
        _avatarKey = UniqueKey();
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _userFuture = Future.error(e);
        });
      }
    }
  }

  Future<void> _navigateToEditProfile(User currentUser) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage(initialProfile: currentUser)),
    );
    if (result == true && mounted) {
      await _handleRefresh();
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(ZoomPageRoute(page: const SettingsPage(), buttonKey: _menuKey));
  }

  void _showPostPopup(BuildContext context, SimplePost post, User user) {
    Navigator.of(context).push(HeroDialogRoute(
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: PostPopupContent(
              post: post,
              user: user,
              onDelete: (deletedPost) => _handleDeletePost(deletedPost.postId),
            ),
          ),
        );
      },
    ));
  }

  Future<void> _handleDeletePost(int postId) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Anda yakin ingin menghapus postingan ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmDelete == true) {
      try {
        await PostService().deletePost(postId);
        await _handleRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Postingan berhasil dihapus.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus postingan: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToFollowersFollowing(User user, int initialTab) async {
    if (user.id == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: user.id!,
          username: user.username,
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

  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    const pageBackgroundColor = Colors.transparent;

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              children: [
                _buildProfileAppBar(null),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                _buildProfileAppBar(null),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildErrorStateWidget(snapshot.error!),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return Column(
              children: [
                _buildProfileAppBar(null),
                const Expanded(child: Center(child: Text("Data pengguna tidak ditemukan."))),
              ],
            );
          }

          final user = snapshot.data!;
          return Column(
            children: [
              _buildProfileAppBar(user),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildProfileHeader(user),
                      if (_showSuggestions) _buildSuggestions(),
                      _buildPostGrid(user),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorStateWidget(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            "Oops, Gagal Memuat Profil",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Sepertinya ada masalah saat mengambil data profil Anda. Mohon periksa koneksi internet dan coba lagi.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleRefresh,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: Colors.orange.withOpacity(0.4),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade800],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return FutureBuilder<List<dynamic>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 230,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 230,
            alignment: Alignment.center,
            child: Text('Gagal memuat saran: ${snapshot.error}'),
          );
        }

        if (snapshot.hasData) {
          final suggestions = snapshot.data!;
          return SuggestionCard(users: suggestions);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileAppBar(User? user) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.username ?? 'Profil',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(width: 5,),
                  if (user?.isVerified ?? false)
                    const VerifiedBadge(size: 18),
                ],
              ),
            ),
            IconButton(
              key: _menuKey,
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: _navigateToSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    const double avatarRadius = 45;
    const String placeholderBanner = 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2070&auto=format&fit=crop';
    final String bannerImageUrl = (user.bannerUrl != null && user.bannerUrl!.isNotEmpty)
        ? user.bannerUrl!
        : placeholderBanner;

    final String heroAvatarTag = 'profile_avatar_hero_${user.id}';

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: bannerImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ImagePlaceholder(),
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: avatarRadius + 22),
                  _buildInfo(user),
                  const SizedBox(height: 8),
                  _buildBio(user),
                  const SizedBox(height: 20),
                  _buildActionButtons(user),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 170 - avatarRadius,
          left: 16,
          right: 16,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAvatarWithStoryAddButton(user, avatarRadius, heroAvatarTag),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0.0),
                    child: _buildStats(user),
                  ),
                ),
              ]
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarWithStoryAddButton(User user, double radius, String heroTag) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircularAvatarFetcher(
                key: _avatarKey,
                radius: radius,
                userId: user.id ?? 0,
                onStoryClosed: _handleRefresh,
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToCreateStory(user),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF03B293), Color(0xFF116C63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostGrid(User user) {
    final posts = user.recentPosts;
    const int columnCount = 3;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 25.0),
      constraints: const BoxConstraints(minHeight: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: (posts.isEmpty)
          ? Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text('Belum ada postingan'),
      )
          : Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 72),
        child: AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final SimplePost post = posts[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 400),
                columnCount: columnCount,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: PressableGridItem(
                      key: ValueKey(post.postId),
                      post: post,
                      user: user,
                      onTap: () {
                        if (post.isVideo) {
                          final fullPostObject = Post(
                            id: post.postId,
                            caption: post.caption,
                            mediaUrl: post.mediaUrl,
                            isVideo: post.isVideo,
                            createdAt: post.createdAt,
                            user: user,
                            likesCount: 0,
                            commentsCount: 0,
                            isLikedByUser: false,
                            isBookmarked: false,
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ClipsViewerPage(initialClip: fullPostObject)));
                        } else {
                          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                          navProvider.showOverlay(PostDetail(postId: post.postId));
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

  Widget _buildStats(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(user.postsCount.toString(), 'postingan'),
        GestureDetector(
          onTap: () => _navigateToFollowersFollowing(user, 0),
          child: _buildStatItem(user.followersCount.toString(), 'pengikut'),
        ),
        GestureDetector(
          onTap: () => _navigateToFollowersFollowing(user, 1),
          child: _buildStatItem(user.followingCount.toString(), 'mengikuti'),
        ),
      ],
    );
  }

  Widget _buildInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.fullName ?? 'Nama tidak tersedia',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildBio(User user) {
    final bioItems = user.bio?.split('\n').where((line) => line.isNotEmpty).toList() ?? [];
    if (bioItems.isEmpty) {
      return const Text("Tidak ada bio", style: TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bioItems.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: Text(item, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4)),
      )).toList(),
    );
  }

  Widget _buildActionButtons(User user) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _navigateToEditProfile(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ShareProfilePage(username: user.username),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Bagikan Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showSuggestions = !_showSuggestions;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0F0F0),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(12),
          ),
          child: Icon(
            _showSuggestions ? Icons.person_add_disabled_outlined : Icons.person_add_alt_1_outlined,
            semanticLabel: _showSuggestions ? 'Sembunyikan Saran' : 'Tampilkan Saran',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontSize: 16, fontWeight:
        FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final List<dynamic> users;
  const SuggestionCard({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
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
              'Temukan Orang',
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
  bool _isLoadingStory = false;

  final FollowService _followService = FollowService();
  final StoryService _storyService = StoryService();

  Future<void> _toggleFollowStatus() async {
    setState(() => _isLoading = true);

    bool success;
    if (_isFollowed) {
      success = await _followService.unfollowUser(widget.user['user_id']);
    } else {
      success = await _followService.followUser(widget.user['user_id']);
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isFollowed = !_isFollowed;
      });

      if (_isFollowed) {
        setState(() => _showShimmer = true);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _showShimmer = false);
          }
        });
      }
    } else {
      final action = _isFollowed ? "berhenti mengikuti" : "mengikuti";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal $action ${widget.user['username']}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] ?? 'No Username';
    final fullName = widget.user['full_name'] ?? 'No Name';
    final bool isFollowBack = widget.user['is_follow_back'] ?? false;
    final String buttonText = _isFollowed ? 'Mengikuti' : (isFollowBack ? 'Ikuti Balik' : 'Ikuti');
    final bool isVerified = widget.user['is_verified'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              log("Profile Card Tapped");
              AppState.navFrom = "profile";

              final userToNavigate = User.fromJson(widget.user);

              NavigationHelper.navigateToProfile(context, userToNavigate);
            },
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: CircularAvatarFetcher(
                          radius: 30,
                          userId: widget.user['user_id'] as int,
                        ),
                      ),
                      if (_isLoadingStory)
                        const SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        SizedBox(width: 2,),
                      if (isVerified)
                        const VerifiedBadge(size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(fullName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _toggleFollowStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowed ? Colors.grey.shade300 : Colors.transparent,
                      shadowColor: _isFollowed ? Colors.black.withOpacity(0.2) : Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: _isFollowed ? 0 : 2,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _isFollowed
                            ? null
                            : LinearGradient(
                          colors: [
                            Colors.amber.shade600,
                            Colors.orange.shade800,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 88, minHeight: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: _isFollowed ? Colors.black54 : Colors.white,
                          ),
                        )
                            : Text(
                          buttonText,
                          style: TextStyle(
                            color: _isFollowed ? Colors.black54 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
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