// lib/components/circular_avatar_fetcher.dart

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

  // Parameter opsional untuk data yang sudah ada
  final String? imageUrl;
  final bool? hasStory;
  final bool? storyViewed;

  // Parameter untuk logika navigasi
  final int? currentUserId;
  final List<UserWithStories>? previousStoriesQueue;
  final List<UserWithStories>? nextStoriesQueue;

  // --- 👇 PERUBAHAN 1: Tambahkan parameter untuk menerima warna yang sudah di-prefetch 👇 ---
  final List<Color>? prefetchedColors;

  const CircularAvatarFetcher({
    super.key,
    required this.userId,
    required this.radius,
    this.onTap,
    this.onStoryClosed,
    this.disableStoryBorder = false,
    this.imageUrl,
    this.hasStory,
    this.storyViewed,
    this.currentUserId,
    this.previousStoriesQueue,
    this.nextStoriesQueue,
    this.prefetchedColors, // <-- Tambahkan ke konstruktor
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
    if (widget.imageUrl == null) {
      _avatarInfoFuture = AvatarService().getCircleAvatarInfo(widget.userId);
    }
  }

  Future<void> _handleTap(Map<String, dynamic> avatarData) async {
    final bool hasStory = widget.hasStory ?? avatarData['has_story'] ?? false;

    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    if (!hasStory || _isLoadingStory) return;

    setState(() => _isLoadingStory = true);

    try {
      // Dengan arsitektur baru, kita tidak perlu mengambil data di sini.
      // Kita hanya perlu menavigasi dan mengirimkan userId.
      final heroTag = 'story_hero_${widget.userId}';

      await Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => StoryViewPage(
            initialUserId: widget.userId,
            heroTag: heroTag,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );

      // Panggil callback setelah halaman cerita ditutup
      widget.onStoryClosed?.call();

    } catch (e) {
      // Tangani error jika navigasi gagal (jarang terjadi)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka cerita: $e')),
        );
      }
    } finally {
      // Pastikan loading indicator selalu hilang, baik sukses maupun gagal
      if (mounted) {
        setState(() => _isLoadingStory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl != null) {
      return _buildAvatar(
        imageUrl: widget.imageUrl,
        hasStory: widget.hasStory ?? false,
        storyViewed: widget.storyViewed ?? true,
      );
    }

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

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          _handleTap({});
        } else {
          _handleTap({
            'has_story': hasStory,
            'profile_picture_url': imageUrl
          });
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