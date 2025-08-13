// lib/widgets/feed/feed_grid.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart'; // PENTING: Import Post Model

class FeedGrid extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts; // <-- PERBAIKAN 1: Terima List<Post>
  final Map<int, int> likeCounts;
  final Map<int, bool> likedPosts;
  final ScrollController scrollController;
  final Animation<double> fadeAnimation;
  final Future<void> Function() onRefresh;
  final Function(Post)
      onLikePost; // <-- PERBAIKAN 2: Callback menerima objek Post
  final Function(Post)
      onPostTap; // <-- PERBAIKAN 3: Callback menerima objek Post
  final Function(Map<String, dynamic>) onUserTap;

  const FeedGrid({
    super.key,
    required this.isLoading,
    required this.posts,
    required this.likeCounts,
    required this.likedPosts,
    required this.scrollController,
    required this.fadeAnimation,
    required this.onRefresh,
    required this.onLikePost,
    required this.onPostTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return const Center(
          child: Text('Tidak ada postingan untuk ditampilkan.'));
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75, // Sesuaikan rasio aspek gambar
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final Post post = posts[index]; // <-- Sekarang ini adalah objek Post

          return GestureDetector(
            onTap: () => onPostTap(post), // <-- PERBAIKAN 4: Kirim objek Post
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.mediaUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                  // Gradient untuk membuat teks lebih mudah dibaca
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Info Pengguna dan Tombol Like
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onUserTap(post.user.toJson()),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: NetworkImage(
                                      post.user.profilePictureUrl ?? ''),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    post.user.username,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onLikePost(
                              post), // <-- PERBAIKAN 5: Kirim objek Post
                          child: Icon(
                            likedPosts[post.id] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: likedPosts[post.id] == true
                                ? Colors.red
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
