// lib/pages/profile_page.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


// Halaman & Komponen UI
import '../components/bottom_navigation.dart';
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),

                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
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

// WIDGET GRID ITEM

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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: 'post-hero-${widget.post.postId}',
              child: CachedNetworkImage(
                imageUrl: widget.post.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
              ),
            ),
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

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin{
  final ProfileService _profileService = ProfileService();
  late Future<User> _userFuture;
  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _onBottomNavTapped(int index) {
    if (index == 4) return;
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    // Tambahkan navigasi lain jika perlu
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Gagal memuat data: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _handleRefresh, child: const Text("Coba Lagi"))

                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Data pengguna tidak ditemukan."));
          }

          final user = snapshot.data!;
          // 2. RefreshIndicator langsung dikembalikan
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                _buildHeader(user),
                SliverToBoxAdapter(child: _buildProfileSection(user)),
                _buildPostGridSliver(user),
              ],
            ),
          );
        },

      ),
      // bottomNavigationBar: CustomBottomNavigation(selectedIndex: 4, onTap: _onBottomNavTapped),
    );
  }

  Widget _buildHeader(User user) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 200,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      centerTitle: true,
      title: Text(
        user.username,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),

      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: _handleRefresh,
          tooltip: 'Perbarui Profil',
        ),
        IconButton(
          key: _menuKey,
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: _navigateToSettings,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(user.profilePictureUrl ?? 'https://i.pinimg.com/1200x/8c/56/c4/8c56c483afc07fbbc8d1c937c53c26b1.jpg'),

              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                user.username,
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFollowersFollowing(User user, int initialTab) async { // <-- Tambahkan async
    if (user.id == null) return;

    // Lakukan perubahan yang sama seperti di other_profile_page
    final result = await Navigator.push<Map<dynamic, dynamic>>( // <-- Tambahkan await
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


  Widget _buildProfileSection(User user) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2),
                      ],
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(user.profilePictureUrl ?? 'https://via.placeholder.com/150'),

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _navigateToEditProfile(user),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? 'Nama tidak tersedia',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),

                ),
                const SizedBox(height: 8),
                Text(
                  user.bio ?? 'Tidak ada bio',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),

                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.12), offset: const Offset(0, 3), blurRadius: 10, spreadRadius: -2),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _navigateToEditProfile(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 3), blurRadius: 10, spreadRadius: -2),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Bagikan Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPostGridSliver(User user) {
    final posts = user.recentPosts;
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(50.0),
            child: Text('Belum ada postingan'),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
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
          childCount: posts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
      ),
    );
  }
}