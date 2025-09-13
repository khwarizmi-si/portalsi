// lib/widgets/feed/feed_grid.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart';
// <-- 1. PASTIKAN MODEL USER SUDAH DI-IMPORT (kemungkinan melalui post_model)
import '../../models/user_model.dart';
import 'animated_feed_grid_item.dart';

class FeedGrid extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;
  final Animation<double> fadeAnimation;
  final Future<void> Function() onRefresh;
  final Function(Post) onLikePost;
  final Function(Post) onPostTap;
  // <-- 2. UBAH TIPE DATA DARI MAP MENJADI USER
  final Function(User) onUserTap;

  const FeedGrid({
    super.key,
    required this.isLoading,
    required this.posts,
    required this.fadeAnimation,
    required this.onRefresh,
    required this.onLikePost,
    required this.onPostTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Tidak ada postingan untuk ditampilkan.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final Post post = posts[index];
            final bool isLiked = post.isLikedByUser;

            return AnimatedFeedGridItem(
              post: post,
              isLiked: isLiked,
              onTap: () => onPostTap(post),
              onLikeTap: () => onLikePost(post),
              // <-- 3. KIRIM OBJEK 'post.user' SECARA LANGSUNG, HAPUS .toJson()
              onUserTap: () => onUserTap(post.user),
            );
          },
          childCount: posts.length,
        ),
      ),
    );
  }
}