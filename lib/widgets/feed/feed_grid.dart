// lib/widgets/feed/feed_grid.dart
import 'package:flutter/material.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import 'animated_feed_grid_item.dart';

class FeedGrid extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;
  final Future<void> Function() onRefresh;
  final Function(Post) onLikePost;
  final Function(Post) onPostTap;
  final Function(User) onUserTap;

  const FeedGrid({
    super.key,
    required this.isLoading,
    required this.posts,
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

    // --- [PERUBAHAN UTAMA] Ganti SliverGrid dengan SliverMasonryGrid.count ---
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, // Tetap 2 kolom
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: posts.length, // Tentukan jumlah item
        itemBuilder: (context, index) {
          final Post post = posts[index];
          final bool isLiked = post.isLikedByUser;

          return AnimatedFeedGridItem(
            post: post,
            isLiked: isLiked,
            onTap: () => onPostTap(post),
            onLikeTap: () => onLikePost(post),
            onUserTap: () => onUserTap(post.user),
          );
        },

      ),
    );
  }
}