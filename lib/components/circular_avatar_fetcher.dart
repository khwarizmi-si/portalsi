import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/story_model.dart';
import '../pages/story_view_page.dart';
import '../services/avatar_service.dart';
import '../services/story_service.dart';

class CircularAvatarFetcher extends StatefulWidget {
  final int userId;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onStoryClosed;
  final bool disableStoryBorder;

  // Parameter opsional baru untuk data yang sudah ada
  final String? imageUrl;
  final bool? hasStory;
  final bool? storyViewed;

  const CircularAvatarFetcher({
    super.key,
    required this.userId,
    required this.radius,
    this.onTap,
    this.onStoryClosed,
    this.disableStoryBorder = false,
    // Tambahkan ke konstruktor
    this.imageUrl,
    this.hasStory,
    this.storyViewed,
  });

  @override
  State<CircularAvatarFetcher> createState() => _CircularAvatarFetcherState();
}

class _CircularAvatarFetcherState extends State<CircularAvatarFetcher> {
  Future<Map<String, dynamic>>? _avatarInfoFuture;
  bool _isLoadingStory = false;

  @override
  void initState() {
    super.initState();
    // HANYA panggil API jika imageUrl TIDAK disediakan
    if (widget.imageUrl == null) {
      _avatarInfoFuture = AvatarService().getCircleAvatarInfo(widget.userId);
    }
  }

  Future<void> _handleTap(Map<String, dynamic> avatarData) async {
    final bool hasStory = avatarData['has_story'] ?? false;

    if (!hasStory) {
      widget.onTap?.call();
      return;
    }

    if (_isLoadingStory) return;

    setState(() => _isLoadingStory = true);

    try {
      final userWithStories = await StoryService().getStoriesForUser(widget.userId);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewPage(
            userWithStories: userWithStories,
            heroTag: 'story_hero_${userWithStories.userId}',
          ),
        ),
      );

      if(mounted) {
        widget.onStoryClosed?.call();
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika data sudah disediakan via parameter, langsung bangun UI tanpa FutureBuilder
    if (widget.imageUrl != null) {
      return _buildAvatar(
        imageUrl: widget.imageUrl,
        hasStory: widget.hasStory ?? false,
        storyViewed: widget.storyViewed ?? true,
      );
    }

    // Jika tidak ada data, gunakan logika FutureBuilder yang lama sebagai fallback
    return FutureBuilder<Map<String, dynamic>>(
      future: _avatarInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPlaceholder();
        }

        final data = snapshot.data!;
        return _buildAvatar(
          imageUrl: data['profile_picture_url'],
          hasStory: data['has_story'] ?? false,
          storyViewed: data['story_viewed'] ?? false,
        );
      },
    );
  }

  // Method builder baru untuk menghindari duplikasi kode
  Widget _buildAvatar({
    required String? imageUrl,
    required bool hasStory,
    required bool storyViewed,
  }) {
    Widget profileAvatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child: imageUrl == null
          ? Icon(Icons.person, size: widget.radius, color: Colors.grey.shade600)
          : null,
    );

    final bool canTapStory = widget.hasStory ?? hasStory;

    return GestureDetector(
      onTap: () {
        if (canTapStory) {
          _handleTap({'has_story': canTapStory});
        } else {
          widget.onTap?.call();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasStory && !widget.disableStoryBorder)
            Container(
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: storyViewed
                    ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300])
                    : const LinearGradient(
                  colors: [Color(0xFF0E7467), Color(0xFFF1892D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: profileAvatar,
              ),
            )
          else
            profileAvatar,

          if (_isLoadingStory)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(
        radius: widget.radius + 4,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      child: Icon(
        Icons.error_outline,
        color: Colors.grey.shade500,
        size: widget.radius,
      ),
    );
  }
}