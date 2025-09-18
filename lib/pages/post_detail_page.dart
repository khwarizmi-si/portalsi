// lib/pages/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:portal_si/components/post_card.dart';
import 'package:provider/provider.dart';
import '../controllers/post_detail_controller.dart';
import '../models/post_model.dart';
import '../helper/time_helper.dart';
import '../utils/navigation_helper.dart';

class PostDetailPage extends StatelessWidget {
  final int postId;
  final Post? initialPost;

  const PostDetailPage(
      {super.key,
      required this.postId,
      this.initialPost,
      required username,
      required String timeAgo,
      required imageUrl,
      required content,
      required comments,
      required profileImageUrl,
      required int likes,
      required isVerified,
      required bool isLiked});

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
        appBar: AppBar(title: const Text("Detail Post")),
        body: Consumer<PostDetailController>(
          builder: (context, controller, _) {
            if (controller.isLoadingMainPost) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.mainPost == null) {
              return const Center(child: Text("Post tidak ditemukan."));
            }

            // Ambil data post utama dari controller
            final Post mainPost = controller.mainPost!;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  // PANGGILAN POSTCARD PERTAMA (LENGKAP)
                  child: PostCard(
                    username: mainPost.user.username,
                    timeAgo:
                        timeAgoFromDate(mainPost.createdAt.toIso8601String()),
                    mediaUrl: mainPost.mediaUrl ?? '', // Ganti imageUrl -> mediaUrl
                    isVideo: mainPost.isVideo,
                    likes: mainPost.likesCount,
                    comments: mainPost.commentsCount,
                    content: mainPost.caption ?? '',
                    isVerified: mainPost.user.isVerified,
                    isLiked: mainPost.isLikedByUser,
                    isBookmarked: false, // Ganti jika ada
                    profileImageUrl: mainPost.user.profilePictureUrl ?? '',
                    user: mainPost.user.toJson(),
                    postId: mainPost.id,
                    onLike: () => controller.toggleLike(mainPost.id),
                    onBookmark: () {},
                    onShare: () {},
                    onComment: () {/* Tampilkan comment sheet */},
                    onProfileTap: () =>
                    {
                      Navigator.pop(context),
                      NavigationHelper.navigateToProfile(
                        context, mainPost.user.toJson()),
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text("Postingan Terkait",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
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
                      // PANGGILAN POSTCARD KEDUA (LENGKAP)
                      return PostCard(
                        username: relatedPost.user.username,
                        timeAgo: timeAgoFromDate(
                            relatedPost.createdAt.toIso8601String()),
                        mediaUrl: relatedPost.mediaUrl ?? '', // Ganti imageUrl -> mediaUrl
                        isVideo: relatedPost.isVideo,
                        comments: relatedPost.commentsCount,
                        content: relatedPost.caption ?? '',
                        isVerified: relatedPost.user.isVerified,
                        isBookmarked: false, // Ganti jika ada
                        profileImageUrl:
                            relatedPost.user.profilePictureUrl ?? '',
                        user: relatedPost.user.toJson(),
                        postId: relatedPost.id,
                        likes: relatedPost.likesCount, // <-- Pastikan ini mengambil data dari controller
                        isLiked: relatedPost.isLikedByUser, // <-- Pastikan ini juga
                        onLike: () => controller.toggleLike(relatedPost.id),
                        onBookmark: () {},
                        onShare: () {},
                        onComment: () {/* Tampilkan comment sheet */},
                        onProfileTap: () => NavigationHelper.navigateToProfile(
                            context, relatedPost.user.toJson()),
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
