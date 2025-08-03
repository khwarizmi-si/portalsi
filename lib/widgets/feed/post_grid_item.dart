// lib/widgets/feed/post_grid_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helper/time_helper.dart';

class PostGridItem extends StatelessWidget {
  final dynamic item;
  final int index;
  final Map<int, int> likeCounts;
  final Map<int, bool> likedPosts;
  final Future<void> Function(Map, int) onLikePost;
  final Function(dynamic) onPostTap;

  const PostGridItem({
    Key? key,
    required this.item,
    required this.index,
    required this.likeCounts,
    required this.likedPosts,
    required this.onLikePost,
    required this.onPostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item == null) return _buildPlaceholderItem();

    final user = item['user'];
    final imageUrl = item['media_url'] ?? '';
    final caption = item['caption'] ?? '';
    final username = user?['username'] ?? 'Unknown User';
    final createdAt = item['created_at'];
    final postId = int.tryParse(item['post_id'].toString()) ?? 0;
    final likesCount = likeCounts[postId] ?? 0;
    final isLiked = likedPosts[postId] ?? false;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onPostTap(item);
          },
          child: Hero(
            tag: 'post_$postId',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageContent(imageUrl),
                    _buildGradientOverlay(),
                    _buildLikeButton(isLiked, likesCount),
                    _buildPostInfo(username, caption, createdAt),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return Container(
      color: Colors.grey[100],
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildImageError(),
            )
          : Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            color: Colors.grey[500],
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            'Image not\navailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          stops: [0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildLikeButton(bool isLiked, int likesCount) {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: () => onLikePost(item, index),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red[400] : Colors.white,
                size: 16,
              ),
              if (likesCount > 0) ...[
                SizedBox(width: 4),
                Text(
                  '$likesCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo(String username, String caption, String? createdAt) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
          if (caption.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
          if (createdAt != null) ...[
            SizedBox(height: 6),
            Text(
              timeAgoFromDate(createdAt),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderItem() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }
}
