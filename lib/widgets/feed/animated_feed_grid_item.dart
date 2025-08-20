// lib/widgets/feed/animated_feed_grid_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_model.dart';
import 'feed_post_preview.dart';

class AnimatedFeedGridItem extends StatefulWidget {
  final Post post;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onUserTap;

  const AnimatedFeedGridItem({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onTap,
    required this.onLikeTap,
    required this.onUserTap,
  });

  @override
  State<AnimatedFeedGridItem> createState() => _AnimatedFeedGridItemState();
}

class _AnimatedFeedGridItemState extends State<AnimatedFeedGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPreviewDialog() {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return FeedPostPreview(post: widget.post);
        },
      ),
    );
  }

  // --- FUNGSI BARU UNTUK onTap ---
  Future<void> _onTapWithAnimation() async {
    // 1. Beri getaran ringan
    HapticFeedback.lightImpact();

    // 2. Jalankan animasi "pop"
    await _animationController.forward();
    await _animationController.reverse();

    // 3. Panggil fungsi navigasi asli setelah animasi selesai
    if (mounted) {
      widget.onTap();
    }
  }

  Future<void> _onLongPress() async {
    HapticFeedback.mediumImpact();
    await _animationController.forward();
    // await _animationController.reverse();
    if (mounted) {
      _showPreviewDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        // --- PERUBAHAN DI SINI ---
        // Panggil fungsi baru yang sudah ada animasinya
        onTap: _onTapWithAnimation,
        onLongPress: _onLongPress,
        // --------------------------
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'feed-post-${widget.post.id}',
                child: Image.network(
                  widget.post.mediaUrl ?? '',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: Colors.grey[200]);
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
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
                        onTap: widget.onUserTap,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(widget.post.user.profilePictureUrl ?? ''),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.post.user.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onLikeTap,
                      child: Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: widget.isLiked ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}