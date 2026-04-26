// lib/pages/post_detail_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
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

  void _handleBack(BuildContext context) {
    if (kIsWeb) {
      // On web the page is shown via showGeneralDialog — use Navigator.pop
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb, // on web let the dialog barrier handle it
      onPopInvoked: (bool didPop) {
        if (!didPop && !kIsWeb) {
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Detail Postingan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed: () => _handleBack(context),
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
                        NavigationHelper.navigateToProfile(context, mainPost.user);
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
                            if (kIsWeb) {
                              // On web the post is in a showGeneralDialog — pop it first
                              Navigator.of(context, rootNavigator: true).pop();
                            } else {
                              Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
                            }
                            Future.delayed(const Duration(milliseconds: 100), () {
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