// lib/pages/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/post_card.dart';
import 'package:portal_si/widgets/comment_section.dart'; // <-- 1. IMPORT WIDGET KOMENTAR
import 'package:provider/provider.dart';
import '../controllers/post_detail_controller.dart';
import '../models/post_model.dart';
import '../helper/time_helper.dart';
import '../utils/navigation_helper.dart';

class PostDetailPage extends StatelessWidget {
  final int postId;
  final Post? initialPost;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
    // Parameter di bawah ini tidak lagi diperlukan karena data diambil dari controller
    // Anda bisa menghapusnya dari mana pun Anda memanggil PostDetailPage
    String? username,
    String? timeAgo,
    String? imageUrl,
    String? content,
    int? comments,
    String? profileImageUrl,
    int? likes,
    bool? isVerified,
    bool? isLiked,
  });

  // --- 2. BUAT FUNGSI UNTUK MENAMPILKAN BOTTOM SHEET ---
  void _showCommentSheet(BuildContext context, int postId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Penting agar sheet bisa setinggi layar
      backgroundColor: Colors.transparent, // Latar belakang transparan
      builder: (context) {
        // Panggil widget CommentSection yang sudah Anda buat
        return CommentSection(postId: postId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = PostDetailController(mainPostId: postId);
        if (initialPost != null) {
          controller.setInitialPost(initialPost!);
        } else {
          controller.loadData();
        }
        return controller;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text("Detail Postingan")),
        body: Consumer<PostDetailController>(
          builder: (context, controller, _) {
            if (controller.isLoadingMainPost) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.mainPost == null) {
              return const Center(child: Text("Post tidak ditemukan."));
            }

            final Post mainPost = controller.mainPost!;
            final heroTag = 'post_hero_${mainPost.id}';

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PostCard(
                    username: mainPost.user.username,
                    timeAgo: timeAgoFromDate(mainPost.createdAt.toIso8601String()),
                    mediaUrl: mainPost.mediaUrl ?? '',
                    isVideo: mainPost.isVideo,
                    likes: mainPost.likesCount,
                    comments: mainPost.commentsCount,
                    content: mainPost.caption ?? '',
                    isVerified: mainPost.user.isVerified,
                    isLiked: mainPost.isLikedByUser,
                    isBookmarked: false,
                    profileImageUrl: mainPost.user.profilePictureUrl ?? '',
                    user: mainPost.user.toJson(),
                    postId: mainPost.id,
                    onLike: () => controller.toggleLike(mainPost.id),
                    onBookmark: () {},
                    onShare: () {},
                    // --- 3. PANGGIL FUNGSI _showCommentSheet ---
                    onComment: () => _showCommentSheet(context, mainPost.id),
                    onProfileTap: () {
                      Navigator.pop(context);
                      NavigationHelper.navigateToProfile(context, mainPost.user.toJson());
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text("Postingan Terkait", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                if (controller.isLoadingRelated)
                  const SliverToBoxAdapter(
                      child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ))),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final relatedPost = controller.relatedPosts[index];
                      return PostCard(
                        username: relatedPost.user.username,
                        timeAgo: timeAgoFromDate(relatedPost.createdAt.toIso8601String()),
                        mediaUrl: relatedPost.mediaUrl ?? '',
                        isVideo: relatedPost.isVideo,
                        comments: relatedPost.commentsCount,
                        content: relatedPost.caption ?? '',
                        isVerified: relatedPost.user.isVerified,
                        isBookmarked: false,
                        profileImageUrl: relatedPost.user.profilePictureUrl ?? '',
                        user: relatedPost.user.toJson(),
                        postId: relatedPost.id,
                        likes: relatedPost.likesCount,
                        isLiked: relatedPost.isLikedByUser,
                        onLike: () => controller.toggleLike(relatedPost.id),
                        onBookmark: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Fitur ini akan segera hadir..',
                              ),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                            ),
                          );
                        },
                        onShare: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Fitur ini akan segera hadir..',
                              ),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                            ),
                          );
                        },
                        // --- 4. PANGGIL FUNGSI YANG SAMA UNTUK POSTINGAN TERKAIT ---
                        onComment: () => _showCommentSheet(context, relatedPost.id),
                        onProfileTap: () => NavigationHelper.navigateToProfile(context, relatedPost.user.toJson()),
                      );
                    },
                    childCount: controller.relatedPosts.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}