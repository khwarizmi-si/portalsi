import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../components/post_header.dart'; // Pastikan path ini benar

class PostCard extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String mediaUrl;
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
  final String? profileImageUrl;
  final Map<String, dynamic> user;
  final int postId;
  final VoidCallback? onProfileTap;
  final bool hasCardDecoration;
  final bool isVideo;

  const PostCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.mediaUrl,
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
    this.hasCardDecoration = true,
    this.isVideo = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isMuted = true;
  bool _wasPlayingBeforeHold = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVideo && widget.mediaUrl != oldWidget.mediaUrl) {
      _videoController?.dispose();
      _initVideoPlayer();
    }
  }

  void _initVideoPlayer() {
    if (widget.isVideo && widget.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
      _videoController!.setLooping(true);
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post-card-${widget.postId}'),
      onVisibilityChanged: (visibilityInfo) {
        if (_videoController == null || !_videoController!.value.isInitialized) return;

        if (visibilityInfo.visibleFraction > 0.6) {
          if (!_videoController!.value.isPlaying) {
            _videoController!.play();
          }
        } else {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          }
        }
      },
      child: Container(
        margin: widget.hasCardDecoration
            ? const EdgeInsets.only(bottom: 8, left: 16, right: 16)
            : EdgeInsets.zero,
        decoration: widget.hasCardDecoration
            ? BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: PostHeader(
                username: widget.username,
                timeAgo: widget.timeAgo,
                profileImageUrl: widget.profileImageUrl ?? '',
                isVerified: widget.isVerified,
                user: widget.user,
                onProfileTap: widget.onProfileTap,
              ),
            ),
            if (widget.mediaUrl.isNotEmpty) _buildMediaWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked ? Colors.red : Colors.black87,
                    onTap: widget.onLike,
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    onTap: widget.onComment,
                  ),
                  _buildActionButton(
                    icon: Icons.send_outlined,
                    onTap: widget.onShare,
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    onTap: widget.onBookmark,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text('${widget.likes} suka', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (widget.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      TextSpan(text: widget.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' ${widget.content}'),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(widget.timeAgo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color ?? Colors.black87, size: 26),
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (widget.isVideo) {
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _videoController != null && _videoController!.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: GestureDetector(
                onTap: _toggleMute,
                onLongPress: () {
                  if (_videoController != null && _videoController!.value.isPlaying) {
                    _wasPlayingBeforeHold = true;
                    _videoController!.pause();
                  }
                },
                onLongPressEnd: (_) {
                  if (_videoController != null && _wasPlayingBeforeHold) {
                    _videoController!.play();
                    _wasPlayingBeforeHold = false;
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    VideoPlayer(_videoController!),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
      );
    } else {
      return Hero(
        tag: 'feed-post-${widget.postId}',
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Image.network(widget.mediaUrl, fit: BoxFit.cover),
        ),
      );
    }
  }
}