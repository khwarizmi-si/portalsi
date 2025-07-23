import 'package:flutter/material.dart';
import '../components/post_header.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String imageUrl;
  final int likes;
  final int comments;
  final String content;
  final bool isVerified;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final String profileImageUrl;
  final Map<String, dynamic> user;
  final int postId;
  final VoidCallback? onProfileTap;

  const PostCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.content,
    required this.isVerified,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
    required this.onComment,
    required this.profileImageUrl,
    required this.user,
    required this.postId,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          12,
        ), // <-- ini membuat sudut membulat
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan padding Instagram-style
          Padding(
            padding: const EdgeInsets.all(12),
            child: PostHeader(
              username: username,
              timeAgo: timeAgo,
              profileImageUrl: profileImageUrl,
              isVerified: isVerified,
              user: user,
              onProfileTap: onProfileTap,
            ),
          ),

          // Image dengan aspect ratio yang konsisten
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.0, // Square seperti Instagram
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade400,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Action buttons dengan style Instagram
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isLiked),
                        color: isLiked ? Colors.red : Colors.black87,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // Comment button
                GestureDetector(
                  onTap: onComment,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ),

                // Share button
                GestureDetector(
                  onTap: onShare,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.send, color: Colors.black87, size: 26),
                  ),
                ),

                const Spacer(),

                // Bookmark button
                GestureDetector(
                  onTap: onBookmark,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        key: ValueKey(isBookmarked),
                        color: Colors.black87,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Likes count
          if (likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$likes suka',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

          // Content/Caption
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$username ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Comments count
          if (comments > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: onComment,
                child: Text(
                  'Lihat semua $comments komentar',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ),

          // Time ago
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              timeAgo,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
