// lib/widgets/single_clip_player.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:portal_si/services/video_cache_service.dart';
import 'package:portal_si/widgets/comment_section.dart';
import 'package:video_player/video_player.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/components/verified_badge.dart';
import 'package:marquee/marquee.dart';
import '../services/like_service.dart';
import '../services/bookmark_service.dart';

class SingleClipPlayer extends StatefulWidget {
  final Post post;
  final bool isActive;

  const SingleClipPlayer({super.key, required this.post, required this.isActive});

  @override
  State<SingleClipPlayer> createState() => _SingleClipPlayerState();
}

class _SingleClipPlayerState extends State<SingleClipPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasMusic = false;
  bool _isInitialized = false;

  final LikeService _likeService = LikeService();
  final BookmarkService _bookmarkService = BookmarkService();

  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  late int _commentsCount;

  Duration? _sliderPosition;
  bool _wasPlayingBeforeDrag = false;

  // --- SINKRONISASI LOOP: Variabel untuk menyimpan posisi terakhir video ---
  Duration _lastPosition = Duration.zero;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser;
    _isBookmarked = widget.post.isBookmarked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _hasMusic = widget.post.musicPreviewUrl != null && widget.post.musicPreviewUrl!.isNotEmpty;

    // Kita tidak lagi set loop di audio player, karena akan dikontrol manual
    // _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _initializePlayer();
  }

  // --- SINKRONISASI LOOP: Fungsi listener untuk mendeteksi video loop ---
  void _videoLoopListener() {
    if (_controller == null || !_controller!.value.isInitialized || !_hasMusic) return;

    final currentPosition = _controller!.value.position;

    // Jika posisi saat ini lebih kecil dari posisi terakhir, artinya video telah loop
    if (currentPosition < _lastPosition) {
      // Perintahkan audio untuk kembali ke awal
      _audioPlayer.seek(Duration.zero);
      // Pastikan audio tetap bermain jika video juga bermain
      if (_controller!.value.isPlaying) {
        _audioPlayer.resume();
      }
    }
    _lastPosition = currentPosition;
  }

  Future<void> _initializePlayer() async {
    final fileInfo = await VideoCacheService().getSingleFile(widget.post.mediaUrl!);
    if (mounted) {
      _controller = VideoPlayerController.file(fileInfo.file)
        ..initialize().then((_) {
          if (mounted) {
            if (_hasMusic) {
              _controller!.setVolume(0.0);
              _audioPlayer.setSourceUrl(widget.post.musicPreviewUrl!);
              // --- SINKRONISASI LOOP: Tambahkan listener di sini ---
              _controller!.addListener(_videoLoopListener);
            } else {
              _controller!.setVolume(1.0);
            }
            setState(() => _isInitialized = true);
            if (widget.isActive) {
              _controller!.play();
              _controller!.setLooping(true);
              if (_hasMusic) {
                _audioPlayer.resume();
              }
            }
          }
        });
      setState(() {});
    }
  }

  @override
  void dispose() {
    // --- SINKRONISASI LOOP: Hapus listener saat widget dihancurkan ---
    _controller?.removeListener(_videoLoopListener);
    _controller?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ... (Sisa kode lain dari didUpdateWidget hingga build tidak ada perubahan) ...
  @override
  void didUpdateWidget(covariant SingleClipPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _updatePlayPauseState();
    }
  }

  void _updatePlayPauseState() {
    if (!_isInitialized || _controller == null) return;
    if (widget.isActive) {
      if (!_controller!.value.isPlaying) _controller!.play();
      _controller!.setLooping(true);
      if (_hasMusic) _audioPlayer.resume();
    } else {
      if (_controller!.value.isPlaying) _controller!.pause();
      if (_hasMusic) _audioPlayer.pause();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        if (_hasMusic) _audioPlayer.pause();
      } else {
        _controller!.play();
        if (_hasMusic) _audioPlayer.resume();
      }
    });
  }

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: CommentSection(
            postId: widget.post.id,
            initialComments: widget.post.comments,
            onCommentAdded: _handleCommentAdded,
          ),
        );
      },
    );
  }

  void _handleCommentAdded() {
    setState(() {
      _commentsCount++;
    });
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount--;
      }
    });

    try {
      await _likeService.toggleLikeHttp(widget.post.id);
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        if (_isLiked) {
          _likesCount++;
        } else {
          _likesCount--;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Gagal memperbarui status suka')),
        );
      }
    }
  }

  void _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      if (_isBookmarked) {
        await _bookmarkService.addBookmark(widget.post.id);
      } else {
        await _bookmarkService.removeBookmark(widget.post.id);
      }
    } catch (e) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Gagal menyimpan post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: ValueListenableBuilder(
        valueListenable: _controller!,
        builder: (context, VideoPlayerValue value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),

              _buildOverlayUI(),

              if (value.isBuffering)
                const CircularProgressIndicator(color: Colors.white),

              Positioned(
                bottom: 85.0,
                left: 0,
                right: 0,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: value.duration.inMilliseconds.toDouble(),
                    value: (_sliderPosition ?? value.position)
                        .inMilliseconds
                        .clamp(0, value.duration.inMilliseconds)
                        .toDouble(),
                    onChangeStart: (newValue) {
                      setState(() {
                        _wasPlayingBeforeDrag = value.isPlaying;
                        if (_wasPlayingBeforeDrag) {
                          _controller!.pause();
                          if (_hasMusic) _audioPlayer.pause();
                        }
                      });
                    },
                    onChanged: (newValue) {
                      setState(() {
                        _sliderPosition = Duration(milliseconds: newValue.round());
                      });
                    },
                    onChangeEnd: (newValue) {
                      final newPosition = Duration(milliseconds: newValue.round());
                      _controller!.seekTo(newPosition);
                      if (_hasMusic) _audioPlayer.seek(newPosition);
                      setState(() {
                        _sliderPosition = null;
                        if (_wasPlayingBeforeDrag) {
                          _controller!.play();
                          if (_hasMusic) _audioPlayer.resume();
                        }
                      });
                    },
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlayUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text('Clips', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool hasMusic = widget.post.musicTrackName != null && widget.post.musicTrackName!.isNotEmpty;
    final String audioText = hasMusic
        ? '${widget.post.musicTrackName!} - ${widget.post.musicArtistName ?? 'Sounds'}'
        : 'Original audio - ${widget.post.user.username}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircularAvatarFetcher(radius: 18, userId: widget.post.user.id ?? 0),
                    const SizedBox(width: 8),
                    Text(widget.post.user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (widget.post.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 14),
                    ],
                  ],
                ),
                if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.post.caption!, style: const TextStyle(color: Colors.white)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 150,
                      height: 20,
                      child: Marquee(
                        text: audioText,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 20.0,
                        velocity: 50.0,
                        pauseAfterRound: const Duration(seconds: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: '$_likesCount',
                onTap: _toggleLike,
                iconColor: _isLiked ? Colors.red : Colors.white,
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.comment,
                label: '$_commentsCount',
                onTap: () => _showCommentSheet(context),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                onTap: _toggleBookmark,
                iconColor: _isBookmarked ? Colors.orangeAccent : Colors.white,
              ),
              const SizedBox(height: 16),
              _buildActionButton(icon: Icons.share),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, String? label, VoidCallback? onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? Colors.white, size: 32),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}