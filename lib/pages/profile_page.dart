// lib/pages/profile_page.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/pages/settings_page.dart';
import 'package:portal_si/pages/share_profile_page.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../components/bottom_navigation.dart';
import '../models/santri_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/santri_service.dart';
import '../services/user_service.dart';
import '../utils/zoom_page_route.dart';
import 'edit_profile_page.dart';
import 'followers_following_page.dart';
import 'link_santri_page.dart';
import 'post_detail.dart';

// --- WIDGET POPUP (MODIFIKASI) ---
class PostPopupContent extends StatefulWidget {
  final Post post;
  final Function(Post) onDelete;
  final Function(Post) onPinPost; // --- [PERUBAHAN BARU] --- Menambahkan callback untuk pin post

  const PostPopupContent({
    Key? key,
    required this.post,
    required this.onDelete,
    required this.onPinPost, // --- [PERUBAHAN BARU] --- Menambahkan ke constructor
  }) : super(key: key);

  @override
  State<PostPopupContent> createState() => _PostPopupContentState();
}

class _PostPopupContentState extends State<PostPopupContent> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.isVideo && widget.post.mediaUrl != null) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl!));
      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        _videoController!.play();
        if (mounted) setState(() {});
      });
      _videoController!.setLooping(true);
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final postUser = widget.post.user;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                  NetworkImage(postUser.profilePictureUrl ?? ''),
                ),
                const SizedBox(width: 8),
                Text(
                  postUser.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  // --- [MODIFIKASI] --- Logika onSelected diubah untuk menangani pin post
                  onSelected: (String value) {
                    // Tutup popup terlebih dahulu
                    Navigator.of(context).pop();

                    // Kemudian jalankan aksi berdasarkan pilihan
                    if (value == 'delete') {
                      widget.onDelete(widget.post);
                    } else if (value == 'pinPost') {
                      widget.onPinPost(widget.post);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Hapus Postingan'),
                    ),
                    // const PopupMenuItem<String>(
                    //   value: 'pinPost',
                    //   child: Text('Pin Postingan ke Beranda'),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: 'post-hero-${widget.post.id}',
                child: _buildMediaContent(),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border,
                            color: Colors.white)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Colors.white)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.send_outlined,
                            color: Colors.white)),
                  ],
                ),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border,
                        color: Colors.white)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.isVideo && _videoController != null) {
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _videoController!.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    VideoPlayer(_videoController!),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        },
      );
    } else {
      return Image.network(
        widget.post.mediaUrl ?? '',
        fit: BoxFit.contain,
      );
    }
  }
}

// --- WIDGET GRID ITEM (Tidak Berubah) ---
class PressableGridItem extends StatefulWidget {
  final Post post;
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
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    if (widget.post.isVideo && widget.post.mediaUrl != null && _thumbnailPath == null) {
      try {
        final path = await VideoThumbnail.thumbnailFile(
          video: widget.post.mediaUrl!,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 300,
          quality: 50,
        );
        if (mounted) {
          setState(() {
            _thumbnailPath = path;
          });
        }
      } catch (e) {
        print('Error generating thumbnail: $e');
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: 'post-hero-${widget.post.id}',
              child: _buildGridContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    Widget content;

    if (widget.post.isVideo) {
      if (_thumbnailPath != null) {
        content = Image.file(
          File(_thumbnailPath!),
          fit: BoxFit.cover,
        );
      } else {
        content = Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
    } else {
      content = Image.network(
        widget.post.mediaUrl ?? '',
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : Container(color: Colors.grey[200]),
        errorBuilder: (context, error, stack) =>
            Container(color: Colors.grey[300]),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        if (widget.post.isVideo)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

// --- ROUTE DIALOG (Tidak Berubah) ---
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
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

// --- PROFILE PAGE & STATE (MODIFIKASI) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isFetchingSantri = false;
  User? _user;
  List<Post> _userPosts = [];
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  final GlobalKey _menuKey = GlobalKey();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- [MODIFIKASI] --- _showPostPopup kini meneruskan fungsi _showPinConfirmationBottomSheet
  void _showPostPopup(BuildContext context, Post post) {
    Navigator.of(context).push(HeroDialogRoute(
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: PostPopupContent(
              post: post,
              onDelete: _handleDeletePost,
              onPinPost: _showPinConfirmationBottomSheet, // Teruskan fungsi ini
            ),
          ),
        );
      },
    ));
  }

  // --- [PERUBAHAN BARU] --- Fungsi untuk menampilkan Bottom Sheet konfirmasi pin post
  void _showPinConfirmationBottomSheet(Post post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.push_pin_outlined,
                size: 40,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sematkan Postingan?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Postingan ini akan disematkan di beranda Anda selama 24 jam. Pengguna lain akan dapat melihatnya di bagian atas feed mereka.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text('Sematkan'),
                      onPressed: () {
                        // TODO: Implementasikan logika penyematan di sini
                        Navigator.of(context).pop(); // Tutup bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Postingan berhasil disematkan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDeletePost(Post post) async {
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
        await PostService().deletePost(post.id);
        setState(() => _userPosts.removeWhere((p) => p.id == post.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Postingan berhasil dihapus.'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menghapus postingan: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  Future<void> _handleBuatPortofolioPressed() async {
    setState(() {
      _isFetchingSantri = true;
    });

    try {
      final List<Santri> santriList = await SantriService().fetchSantriList();
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return LinkSantriPage(santriList: santriList);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data santri: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingSantri = false;
        });
      }
    }
  }
  void _navigateToSettings() {
    Navigator.of(context).push(
      ZoomPageRoute(
        page: const SettingsPage(),
        buttonKey: _menuKey,
      ),
    );
  }
  Future<void> _loadAllData() async {
    setStateIfMounted(() => _isLoading = true);
    try {
      final user = await ProfileService().getProfile();
      if (!mounted) return;
      setStateIfMounted(() => _user = user);
      final userId = user.id;
      if (userId == null) {
        throw Exception('User ID tidak valid.');
      }
      final userPostsResult = await _fetchUserPosts(userId);
      await _fetchFollowData(userId);
      if (mounted) {
        setStateIfMounted(() {
          _userPosts = userPostsResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setStateIfMounted(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }
  // lib/pages/profile_page.dart -> di dalam fungsi _fetchUserPosts

  Future<List<Post>> _fetchUserPosts(int userId) async {
    // Ganti menjadi 'fetchPosts' sesuai yang ada di PostService
    final allPosts = await PostService().fetchPosts(); // <--- NAMA YANG BENAR
    return allPosts.where((post) => post.user.id == userId).toList();
  }
  Future<void> _fetchFollowData(int userId) async {
    try {
      final followersData = await FollowService().getFollowers(userId);
      final followingData = await FollowService().getFollowing(userId);
      setStateIfMounted(() {
        _followers = followersData;
        _following = followingData;
      });
    } catch (e) {
      print("Error loading follow data: $e");
    }
  }
  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(initialProfile: _user!)),
    );
    if (result == true) {
      _loadAllData();
    }
  }
  void _navigateToFollowersFollowing(int initialTab) {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingPage(
          userId: _user!.id!,
          initialTab: initialTab,
          followers: _followers,
          following: _following,
        ),
      ),
    );
  }
  void _onBottomNavTapped(int index) {
    if (index == 4) return;
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar:
      CustomBottomNavigation(selectedIndex: 4, onTap: _onBottomNavTapped),
    );
  }
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Gagal memuat data: $_error"),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadAllData, child: const Text("Coba Lagi"))
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildProfileSection()),
          _buildPostGridSliver(),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: 200,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      centerTitle: true,
      title: Text(
        _user?.username ?? 'Profil',
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
      ),
      actions: [
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
              image: NetworkImage(_user?.profilePictureUrl ??
                  'https://i.pinimg.com/1200x/8c/56/c4/8c56c483afc07fbbc8d1c937c53c26b1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                _user?.username ?? 'Nama tidak tersedia',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildProfileSection() {
    return Container(
      color: Colors.white,
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
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(_user?.profilePictureUrl ??
                            'https://via.placeholder.com/150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _navigateToEditProfile,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 12),
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
                    _buildStatItem(_userPosts.length.toString(), 'postingan'),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(0),
                      child: _buildStatItem(
                          _followers.length.toString(), 'pengikut'),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToFollowersFollowing(1),
                      child: _buildStatItem(
                          _following.length.toString(), 'mengikuti'),
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
                  _user?.fullName ?? 'Nama tidak tersedia',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.bio ?? 'Tidak ada bio',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.3),
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
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit profile',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_user != null) {
                        final username =
                            _user?.username ?? 'username_not_found';
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) =>
                                ShareProfilePage(username: username),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Bagikan Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x83B98946),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // child: ElevatedButton(
                  //   onPressed: _isFetchingSantri
                  //       ? null
                  //       : _handleBuatPortofolioPressed,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFFFFC87B),
                  //     foregroundColor: Colors.grey[800],
                  //     elevation: 0,
                  //     padding: const EdgeInsets.symmetric(vertical: 12),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  //   child: _isFetchingSantri
                  //       ? const SizedBox(
                  //     height: 20,
                  //     width: 20,
                  //     child: CircularProgressIndicator(
                  //       strokeWidth: 2.5,
                  //       color: Colors.white,
                  //     ),
                  //   )
                  //       : const Text(
                  //     'Buat Portofolio',
                  //     style: TextStyle(
                  //       fontWeight: FontWeight.w600,
                  //       fontSize: 14,
                  //     ),
                  //   ),
                  // ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
  Widget _buildPostGridSliver() {
    if (_userPosts.isEmpty) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final Post post = _userPosts[index];
            return PressableGridItem(
              post: post,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetail(post: post),
                  ),
                );
              },
              onLongPress: () {
                _showPostPopup(context, post);
              },
            );
          },
          childCount: _userPosts.length,
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