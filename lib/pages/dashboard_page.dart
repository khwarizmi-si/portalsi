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
  // 1. Tambahkan kembali state untuk mendeteksi scroll
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    // 2. Tambahkan kembali listener untuk scroll controller
    _scrollController.addListener(() {
      // Cek jika posisi scroll lebih dari 10
      final isScrolled = _scrollController.offset > 10;
      // Hanya panggil setState jika nilainya berubah untuk efisiensi
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
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
          backgroundColor: Colors
              .transparent, // biar gradient container yang keliatan, bukan warna Scaffold
          appBar: _buildAppBar(context),
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

  // 3. Perbarui AppBar menjadi versi lengkap dengan animasi dan tombol aksi
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
              fontSize: 24, // Sedikit lebih besar untuk tampilan utama
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

  Widget _buildBody(BuildContext context, HomeController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }
    if (controller.posts.isEmpty) {
      return const Center(child: Text('Tidak ada post untuk ditampilkan.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchPosts(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(child: StorySection()),
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

                  // Pastikan _showCommentSheet dipanggil dari context yang benar
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
}
