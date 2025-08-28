// lib/widgets/feed/feed_grid.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import 'animated_feed_grid_item.dart';

class FeedGrid extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;
  // final Map<int, int> likeCounts;
  // final Map<int, bool> likedPosts;
  // 1. Hapus scrollController dari parameter
  // final ScrollController scrollController;
  final Animation<double> fadeAnimation;
  final Future<void> Function() onRefresh;
  final Function(Post) onLikePost;
  final Function(Post) onPostTap;
  final Function(Map<String, dynamic>) onUserTap;

  const FeedGrid({
    super.key,
    required this.isLoading,
    required this.posts,
    // required this.likeCounts,
    // required this.likedPosts,
    // required this.scrollController, // Hapus
    required this.fadeAnimation,
    required this.onRefresh,
    required this.onLikePost,
    required this.onPostTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      // Untuk sliver, kita kembalikan widget yang sesuai
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (posts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Tidak ada postingan untuk ditampilkan.')),
      );
    }

    // 2. Ubah dari GridView.builder menjadi SliverGrid
    // Bungkus dengan SliverPadding untuk memberi ruang di sekitar grid
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

            // Logika item tidak berubah
            return AnimatedFeedGridItem(
              post: post,
              isLiked: isLiked,
              onTap: () => onPostTap(post),
              onLikeTap: () => onLikePost(post),
              onUserTap: () => onUserTap(post.user.toJson()),
            );
          },
          childCount: posts.length,
        ),
      ),
    );
  }
}