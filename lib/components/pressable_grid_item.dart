// lib/components/pressable_grid_item.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../components/video_thumbnail_widget.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/bookmark_service.dart';
import '../services/like_service.dart';

// WIDGET UNTUK SHIMMER PLACEHOLDER
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }
}

// WIDGET Tombol yang bisa bereaksi terhadap hover
class HoverableButton extends StatefulWidget {
  final ValueNotifier<bool> isHoveredNotifier;
  final String? text;
  final IconData icon;
  final bool isFilled;

  const HoverableButton({
    Key? key,
    required this.isHoveredNotifier,
    this.text,
    required this.icon,
    this.isFilled = false,
  }) : super(key: key);

  @override
  State<HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<HoverableButton> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    widget.isHoveredNotifier.addListener(_onHoverChanged);
  }

  @override
  void dispose() {
    widget.isHoveredNotifier.removeListener(_onHoverChanged);
    super.dispose();
  }

  // --- 👇 PERUBAHAN ADA DI SINI 👇 ---
  void _onHoverChanged() {
    if (mounted && _isHovered != widget.isHoveredNotifier.value) {
      setState(() {
        _isHovered = widget.isHoveredNotifier.value;
        // Jika tombol mulai di-hover (berubah jadi oranye), berikan getaran kecil
        if (_isHovered) {
          HapticFeedback.lightImpact();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.white;
    Color backgroundColor = Colors.black.withOpacity(0.4);

    if (widget.isFilled && !_isHovered) {
      backgroundColor = Colors.white.withOpacity(0.9);
      iconColor = Colors.red;
    } else if (_isHovered) {
      backgroundColor = Colors.orange.shade700;
      iconColor = Colors.white;
    }

    if(widget.icon == Icons.bookmark && widget.isFilled && !_isHovered) {
      iconColor = Colors.blue.shade700;
    }


    return AnimatedScale(
      scale: _isHovered ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: iconColor, size: 18),
            if (widget.text != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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

// WIDGET KONTEN POPUP
class TransientPostPreview extends StatelessWidget {
  final SimplePost post;
  final User user;
  final Map<String, GlobalKey> buttonKeys;
  final Map<String, ValueNotifier<bool>> buttonHoverNotifiers;

  const TransientPostPreview({
    Key? key,
    required this.post,
    required this.user,
    required this.buttonKeys,
    required this.buttonHoverNotifiers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.white;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.profilePictureUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ImagePlaceholder(),
                            errorWidget: (context, url, error) => const CircleAvatar(backgroundColor: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: 'post-hero-${post.postId}',
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const AspectRatio(
                        aspectRatio: 1,
                        child: ImagePlaceholder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HoverableButton(
                      key: buttonKeys['like'],
                      isHoveredNotifier: buttonHoverNotifiers['like']!,
                      icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                      isFilled: post.isLikedByUser,
                    ),
                    const SizedBox(width: 8),
                    HoverableButton(
                      key: buttonKeys['comment'],
                      isHoveredNotifier: buttonHoverNotifiers['comment']!,
                      icon: Icons.chat_bubble_outline,
                    ),
                  ],
                ),
                HoverableButton(
                  key: buttonKeys['bookmark'],
                  isHoveredNotifier: buttonHoverNotifiers['bookmark']!,
                  icon: post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  isFilled: post.isBookmarked,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET UTAMA
class PressableGridItem extends StatefulWidget {
  final SimplePost post;
  final User user;
  final VoidCallback onTap;

  const PressableGridItem({
    Key? key,
    required this.post,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PressableGridItem> createState() => _PressableGridItemState();
}

class _PressableGridItemState extends State<PressableGridItem> {
  late SimplePost _post;
  OverlayEntry? _overlayEntry;
  bool _isPressed = false;

  final LikeService _likeService = LikeService();
  final BookmarkService _bookmarkService = BookmarkService();

  final Map<String, GlobalKey> _buttonKeys = {
    'like': GlobalKey(),
    'comment': GlobalKey(),
    'bookmark': GlobalKey(),
  };
  final Map<String, ValueNotifier<bool>> _buttonHoverNotifiers = {
    'like': ValueNotifier(false),
    'comment': ValueNotifier(false),
    'bookmark': ValueNotifier(false),
  };

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _removePreviewOverlay();
    _buttonHoverNotifiers.forEach((_, notifier) => notifier.dispose());
    super.dispose();
  }

  void _showPreviewOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Center(
              child: TransientPostPreview(
                post: _post,
                user: widget.user,
                buttonKeys: _buttonKeys,
                buttonHoverNotifiers: _buttonHoverNotifiers,
              ),
            ),
          ],
        );
      },
    );

    overlayState?.insert(_overlayEntry!);
  }

  void _removePreviewOverlay() async {
    if (_buttonHoverNotifiers['like']!.value) {
      await _handleLike();
    } else if (_buttonHoverNotifiers['comment']!.value) {
      _handleComment();
    } else if (_buttonHoverNotifiers['bookmark']!.value) {
      await _handleBookmark();
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
    _buttonHoverNotifiers.forEach((_, notifier) => notifier.value = false);
  }

  Future<void> _handleLike() async {
    final originalStatus = _post.isLikedByUser;
    setState(() {
      _post = _post.copyWith(isLikedByUser: !originalStatus);
    });
    try {
      await _likeService.toggleLikeHttp(_post.postId);
      print("✅ Like toggled successfully");
    } catch (e) {
      setState(() {
        _post = _post.copyWith(isLikedByUser: originalStatus);
      });
      print("❌ Failed to toggle like: $e");
    }
  }

  Future<void> _handleBookmark() async {
    final originalStatus = _post.isBookmarked;
    setState(() {
      _post = _post.copyWith(isBookmarked: !originalStatus);
    });
    try {
      if (_post.isBookmarked) {
        await _bookmarkService.addBookmark(_post.postId);
      } else {
        await _bookmarkService.removeBookmark(_post.postId);
      }
      print("✅ Bookmark toggled successfully");
    } catch (e) {
      setState(() {
        _post = _post.copyWith(isBookmarked: originalStatus);
      });
      print("❌ Failed to toggle bookmark: $e");
    }
  }

  void _handleComment() {
    widget.onTap();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _buttonKeys.forEach((key, globalKey) {
      final RenderBox? buttonRenderBox = globalKey.currentContext?.findRenderObject() as RenderBox?;
      if (buttonRenderBox == null) return;

      final buttonRect = Rect.fromPoints(
        buttonRenderBox.localToGlobal(Offset.zero),
        buttonRenderBox.localToGlobal(buttonRenderBox.size.bottomRight(Offset.zero)),
      );

      final fingerPosition = details.globalPosition;
      final notifier = _buttonHoverNotifiers[key]!;

      if (buttonRect.contains(fingerPosition)) {
        if (!notifier.value) notifier.value = true;
      } else {
        if (notifier.value) notifier.value = false;
      }
    });
  }

  void _onTapDown(TapDownDetails details) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }
  void _onTapCancel() {
    if(mounted){
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mediaDisplay;
    if (_post.isVideo) {
      mediaDisplay = VideoThumbnailWidget(videoUrl: _post.mediaUrl);
    } else {
      mediaDisplay = CachedNetworkImage(
        imageUrl: _post.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ImagePlaceholder(),
        errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: () => _showPreviewOverlay(context),
      onLongPressUp: () => _removePreviewOverlay(),
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(40.0),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_post.isVideo)
                mediaDisplay
              else
                Hero(
                  tag: 'post-hero-${_post.postId}',
                  child: mediaDisplay,
                ),
              if (_post.isVideo)
                const Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Icon(
                    Icons.video_camera_back_rounded,
                    color: Colors.white,
                    size: 22.0,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}