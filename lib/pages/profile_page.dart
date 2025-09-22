// lib/pages/profile_page.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

// Halaman & Komponen UI
import '../components/video_thumbnail_widget.dart';
import '../providers/scroll_provider.dart';
import '../utils/navigation_helper.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'post_detail.dart';
import 'settings_page.dart';
import 'share_profile_page.dart';

// Model & Service
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';

// Helper & Util
import '../utils/zoom_page_route.dart';


import 'package:palette_generator/palette_generator.dart';

// --- WIDGET POPUP, GRID ITEM, DAN HERO DIALOG ROUTE TETAP SAMA ---
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
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.post.mediaUrl),
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
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.user.profilePictureUrl ?? ''),
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
                child: Image.network(widget.post.mediaUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PressableGridItem extends StatefulWidget {
  final SimplePost post;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PressableGridItem({
    Key? key,
    required this.post,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<PressableGridItem> createState() => _PressableGridItemState();
}

class _PressableGridItemState extends State<PressableGridItem> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _isPressed = false);
  void _onLongPress() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _isPressed = false);
        widget.onLongPress();
      }
    });
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
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: _onLongPress,
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
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
          child: Hero(
            tag: 'post-hero-${widget.post.postId}',
            child: mediaDisplay,
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


// --- WIDGET UTAMA HALAMAN PROFIL ---

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  final ProfileService _profileService = ProfileService();
  late Future<User> _userFuture;
  final GlobalKey _menuKey = GlobalKey();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadData();

    // 3. INISIALISASI CONTROLLER DAN TAMBAHKAN LISTENER
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
      final direction = _scrollController.position.userScrollDirection;

      // Jika user scroll ke ATAS (reverse), maka tampilkan teks.
      if (direction == ScrollDirection.reverse) {
        scrollProvider.setScrolled(true);
      }
      // Jika user scroll ke BAWAH (forward), maka sembunyikan teks.
      else if (direction == ScrollDirection.forward) {
        scrollProvider.setScrolled(false);
      }
    });
  }

  // 4. JANGAN LUPA DISPOSE CONTROLLER
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _userFuture = _profileService.getProfile();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _userFuture = _profileService.refreshProfile();
    });
  }

  // Kode logic lainnya tetap sama
  Future<void> _navigateToEditProfile(User currentUser) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage(initialProfile: currentUser)),
    );
    if (result == true && mounted) {
      _handleRefresh();
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
        _handleRefresh();
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
    final result = await Navigator.push<Map<dynamic, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: user.id!,
          initialTab: initialTab,
        ),
      ),
    );
    if (result != null && mounted) {
      NavigationHelper.navigateToProfile(
        context,
        Map<String, dynamic>.from(result),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Gagal memuat data: ${snapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _handleRefresh, child: const Text("Coba Lagi")),
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
          // Seluruh halaman dibungkus Column
          return Column(
            children: [
              // 1. AppBar statis di paling atas
              _buildProfileAppBar(user),

              // 2. Konten yang bisa scroll dibungkus Expanded
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildBannerAndHeader(user),
                      _buildProfileBody(user),
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


  // --- PERUBAHAN 2: FUNGSI BUILD WIDGET DISESUAIKAN ---
  // Fungsi-fungsi ini tidak lagi mengembalikan 'Sliver'

  Widget _buildProfileAppBar(User? user) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                user?.username ?? 'Profil',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
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

  // Nama diubah dari _buildBannerAndHeaderSliver menjadi _buildBannerAndHeader
  Widget _buildBannerAndHeader(User user) {
    const double avatarRadius = 45;
    const String placeholderBanner = 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2070&auto=format&fit=crop';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(user.profilePictureUrl ?? placeholderBanner),
                fit: BoxFit.cover,
              )),
        ),
        Positioned(
          top: 165 - avatarRadius,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAvatar(user, avatarRadius),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildStats(user),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // Nama diubah dari _buildProfileBodySliver menjadi _buildProfileBody
  Widget _buildProfileBody(User user) {
    const double avatarRadius = 45;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: avatarRadius + 16),
          _buildInfo(user),
          const SizedBox(height: 8),
          _buildBio(user),
          const SizedBox(height: 20),
          _buildActionButtons(user),
        ],
      ),
    );
  }

  // Nama diubah dari _buildPostGridSliver menjadi _buildPostGrid
  Widget _buildPostGrid(User user) {
    final posts = user.recentPosts;

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
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: GridView.builder(
          // PENTING: Dua properti ini wajib ada di dalam ListView
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final SimplePost post = posts[index];
            return PressableGridItem(
              post: post,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetail(postId: post.postId)));
              },
              onLongPress: () {
                _showPostPopup(context, post, user);
              },
            );
          },
        ),
      ),
    );
  }

  // --- Widget-widget lainnya tetap sama (tidak diubah) ---

  Widget _buildAvatar(User user, double radius) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFAFAFA), width: 4),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundImage: CachedNetworkImageProvider(
                user.profilePictureUrl ?? 'https://via.placeholder.com/150'),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF03B293),
                  Color(0xFF116C63),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFAFAFA), width: 2),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
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
        Text(
          "Visual Creator",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        )
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
        padding: const EdgeInsets.only(bottom: 8.0),
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
            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}