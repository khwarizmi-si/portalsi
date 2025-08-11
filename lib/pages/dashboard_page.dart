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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCommentSheet(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Penting agar sheet bisa tinggi
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          // Batasi tinggi sheet maksimal 90% layar
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
          appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    // Implementasi AppBar Anda di sini
    return AppBar(title: const Text('Portal SI'));
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
                  isBookmarked: false, // Ganti dengan data asli jika ada
                  profileImageUrl: post.user.profilePictureUrl ?? '',
                  user: post.user.toJson(), // Kirim data user untuk navigasi
                  onLike: () => controller.toggleLike(post.id),
                  onBookmark: () {/* Panggil controller */},
                  onShare: () {/* Panggil controller */},
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
