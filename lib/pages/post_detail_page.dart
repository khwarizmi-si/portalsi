// lib/pages/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/post_card.dart';
import 'package:portal_si/providers/navigation_provider.dart'; // <-- Impor
import 'package:portal_si/widgets/comment_section.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../controllers/post_detail_controller.dart';
import '../models/post_model.dart';
import '../utils/navigation_helper.dart';

class PostDetailPage extends StatelessWidget {
  final int postId;
  final Post? initialPost;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  void _showCommentSheet(BuildContext context, Post post) {
    AppState.commentFrom = "post_detail_page";
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSection(
        postId: post.id,
        initialComments: post.comments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // --- PERUBAHAN 1: Bungkus dengan PopScope ---
    return PopScope(
      canPop: navProvider.overlayPage == null,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          navProvider.hideOverlay();
        }
      },
      child: ChangeNotifierProvider(
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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Detail Postingan"),
            // --- PERUBAHAN 2: Tambahkan tombol kembali kustom ---
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (navProvider.overlayPage != null) {
                  navProvider.hideOverlay();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
          ),
          body: Consumer<PostDetailController>(
            builder: (context, controller, _) {
              if (controller.isLoadingMainPost) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.mainPost == null) {
                return const Center(child: Text("Post tidak ditemukan."));
              }

              final Post mainPost = controller.mainPost!;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: PostCard(
                      post: mainPost,
                      onLike: () => controller.toggleLike(mainPost.id),
                      onBookmark: () {},
                      onShare: () {},
                      onComment: () => _showCommentSheet(context, mainPost),
                      onProfileTap: () {
                        // Cukup panggil helper, ia akan menangani sisanya
                        NavigationHelper.navigateToProfile(
                            context, mainPost.user);
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
                        return PostCard(
                          post: relatedPost,
                          onLike: () => controller.toggleLike(relatedPost.id),
                          onBookmark: () {},
                          onShare: () {},
                          onComment: () =>
                              _showCommentSheet(context, relatedPost),
                          onProfileTap: () {
                            Provider.of<NavigationProvider>(context,
                                    listen: false)
                                .hideOverlay();
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              NavigationHelper.navigateToProfile(
                                  context, relatedPost.user);
                            });
                          },
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
      ),
    );
  }
}
