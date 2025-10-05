// lib/components/post_action_counts.dart
import 'package:flutter/material.dart';
import 'package:portal_si/models/post_model.dart';

class PostActionCounts extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;

  const PostActionCounts({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          _buildActionItem(
            icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
            iconColor: post.isLikedByUser ? Colors.red : Colors.black87,
            count: post.likesCount,
            onTap: onLike,
          ),
          const SizedBox(width: 16),
          _buildActionItem(
            icon: Icons.chat_bubble_outline,
            count: post.commentsCount,
            onTap: onComment,
          ),
          const SizedBox(width: 16),
          // _buildActionItem(
          //   icon: Icons.send_outlined,
          //   onTap: onShare,
          // ),
          const Spacer(),
          IconButton(
            onPressed: onBookmark,
            icon: Icon(
              post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: post.isBookmarked ? Colors.blue.shade700 : Colors.black87,
            ),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    int? count,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.black87, size: 28),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}