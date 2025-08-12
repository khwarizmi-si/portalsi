// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/post_card.dart';
import 'package:portal_si/components/story_section.dart';
import 'package:portal_si/widgets/comment_section.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../models/post_model.dart';
import '../components/bottom_navigation.dart';
import '../helper/time_helper.dart';
import '../utils/navigation_helper.dart';
import 'message_list_page.dart'; // <-- JANGAN LUPA IMPORT INI

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

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

    // PENTING: Panggil fetchPosts saat halaman pertama kali dibuka
    // Pastikan HomeController Anda dipanggil di sini jika belum ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeController>(context, listen: false)
          .fetchPosts(isRefresh: true);
    });
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
  Widget build(BuildContext context) {
    // ChangeNotifierProvider harus berada di atas widget yang akan mengaksesnya.
    // Memindahkannya ke atas MaterialApp atau di atas widget ini adalah praktik yang baik.
    // Untuk contoh ini, kita asumsikan sudah ada di atasnya atau kita bungkus di sini.
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Container(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context),
          // Gunakan Consumer di sini untuk rebuild saat data berubah
          body: Consumer<HomeController>(
            builder: (context, controller, _) {
              return _buildBody(context, controller);
            },
          ),
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: 0,
            onTap: (index) {/* Logika Navigasi */},
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: _isScrolled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Portal SI',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessageListPage()),
                );
              },
              icon: const Icon(
                Icons.send_outlined,
                color: Colors.black,
              ),
              tooltip: 'Pesan',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // Widget untuk membangun body utama
  Widget _buildBody(BuildContext context, HomeController controller) {
    if (controller.isLoading && controller.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }
    if (controller.posts.isEmpty && controller.pinnedPost == null) {
      return const Center(child: Text('Tidak ada post untuk ditampilkan.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchPosts(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Story Section
          const SliverToBoxAdapter(child: StorySection()),

          // 2. Pinned Post Section (BARU)
          _buildPinnedPost(context, controller),

          // 3. Regular Posts List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final Post post = controller.posts[index];
                return PostCard(
                  username: post.user.username,
                  timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
                  imageUrl: post.mediaUrl ?? '',
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
                  onComment: () => _showCommentSheet(context, post.id),
                  postId: post.id,
                  onProfileTap: () => NavigationHelper.navigateToProfile(
                      context, post.user.toJson()),
                );
              },
              childCount: controller.posts.length,
            ),
          ),
        ],
      ),
    );
  }

  // Widget baru untuk menampilkan pinned post jika ada (BARU)
  Widget _buildPinnedPost(BuildContext context, HomeController controller) {
    final pinnedPost = controller.pinnedPost;

    // Jika tidak ada pinned post, jangan tampilkan apa-apa
    if (pinnedPost == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Cek apakah post sudah lebih dari 24 jam
    final bool isExpired =
        DateTime.now().difference(pinnedPost.createdAt).inHours >= 24;

    if (isExpired) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Jika ada dan belum kedaluwarsa, tampilkan dengan widget khusus
    return SliverToBoxAdapter(
      child: _PinnedPostCard(
        post: pinnedPost,
        controller: controller, // Teruskan controller
        onComment: () => _showCommentSheet(context, pinnedPost.id),
      ),
    );
  }
}

// Widget khusus untuk tampilan Pinned Post (BARU)
class _PinnedPostCard extends StatelessWidget {
  final Post post;
  final HomeController controller;
  final VoidCallback onComment;

  const _PinnedPostCard({
    required this.post,
    required this.controller,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.yellow.shade50,
            Colors.amber.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header untuk "Pengumuman"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.push_pin, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Pengumuman Disematkan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Gunakan PostCard yang sudah ada untuk konsistensi
          // Kita bungkus dengan Padding agar tidak menempel ke tepi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: PostCard(
              username: post.user.username,
              timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
              imageUrl: post.mediaUrl ?? '',
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
              onProfileTap: () => NavigationHelper.navigateToProfile(
                  context, post.user.toJson()),
              // Atur agar PostCard tidak punya background/shadow sendiri
              hasCardDecoration: false,
            ),
          ),
        ],
      ),
    );
  }
}
