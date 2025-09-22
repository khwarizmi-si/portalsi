// lib/widgets/feed/animated_feed_grid_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/video_thumbnail_widget.dart';
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

  // --- FUNGSI-FUNGSI LAINNYA TETAP SAMA ---
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

  Future<void> _onTapWithAnimation() async {
    HapticFeedback.lightImpact();
    await _animationController.forward();
    await _animationController.reverse();
    if (mounted) {
      widget.onTap();
    }
  }

  Future<void> _onLongPress() async {
    HapticFeedback.mediumImpact();
    await _animationController.forward();
    if (mounted) {
      _showPreviewDialog();
    }
  }


  // --- [PERUBAHAN UTAMA ADA DI FUNGSI build()] ---
  @override
  Widget build(BuildContext context) {
    Widget mediaDisplay;

    // Cek apakah URL media valid
    final bool hasMediaUrl = widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty;

    if (hasMediaUrl) {
      if (widget.post.isVideo) {
        mediaDisplay = VideoThumbnailWidget(videoUrl: widget.post.mediaUrl!);
      } else {
        mediaDisplay = Image.network(
          widget.post.mediaUrl!,
          fit: BoxFit.cover,
          // Selama loading, tampilkan placeholder abu-abu
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(color: Colors.grey[200]);
          },
          // Jika gambar gagal di-load, tampilkan ikon broken image
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[400]),
          ),
        );
      }
    } else {
      // Jika tidak ada URL sama sekali, tampilkan placeholder
      mediaDisplay = Container(
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _onTapWithAnimation,
        onLongPress: _onLongPress,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // [SOLUSI] Bungkus SEMUANYA dengan AspectRatio
              // Ini memastikan widget selalu punya ukuran yang pasti
              AspectRatio(
                // Jika aspectRatio null, gunakan 1.0 (persegi) sebagai fallback.
                aspectRatio: widget.post.aspectRatio ?? 1.0,
                child: mediaDisplay,
              ),
              // ... Sisa kode untuk Gradient dan User Info tetap sama ...
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