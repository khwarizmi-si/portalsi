// lib/widgets/single_clip_player.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/services/follow_service.dart'; // <-- 1. TAMBAHAN: Impor FollowService
import 'package:portal_si/services/video_cache_service.dart';
import 'package:portal_si/widgets/comment_section.dart';
import 'package:video_player/video_player.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/components/verified_badge.dart';
import 'package:marquee/marquee.dart';
import '../services/like_service.dart';
import '../services/bookmark_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/secure_storage.dart';

class SingleClipPlayer extends StatefulWidget {
  final Post post;
  final bool isActive;
  final VideoPlayerController? preInitializedController;

  const SingleClipPlayer({
    super.key,
    required this.post,
    required this.isActive,
    this.preInitializedController,
  });

  @override
  State<SingleClipPlayer> createState() => _SingleClipPlayerState();
}

class _SingleClipPlayerState extends State<SingleClipPlayer>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  VideoPlayerController? _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasMusic = false;
  bool _isInitialized = false;

  // --- 2. TAMBAHAN: Inisialisasi service dan state management ---
  final LikeService _likeService = LikeService();
  final BookmarkService _bookmarkService = BookmarkService();
  final FollowService _followService = FollowService(); // Buat instance FollowService

  int? _currentUserId; // State untuk menyimpan ID user yang sedang login
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  late int _commentsCount;
  late bool _isFollowing; // State untuk status follow

  Duration? _sliderPosition;
  bool _wasPlayingBeforeDrag = false;
  Duration _lastPosition = Duration.zero;

  late AnimationController _pauseIconAnimationController;
  late Animation<double> _pauseIconAnimation;
  bool _showPauseIcon = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByUser;
    _isBookmarked = widget.post.isBookmarked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _hasMusic = widget.post.musicPreviewUrl != null &&
        widget.post.musicPreviewUrl!.isNotEmpty;

    // --- 3. PERUBAHAN: Panggil fungsi untuk memuat data awal ---
    _isFollowing = false; // Nilai default sementara
    _loadInitialData(); // Memuat ID user dan status follow

    _pauseIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _pauseIconAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _pauseIconAnimationController, curve: Curves.easeInOut));

    if (widget.preInitializedController != null) {
      _setupExistingController();
    } else {
      _initializeNewController();
    }
  }

  // --- 4. TAMBAHAN: Fungsi untuk mengambil data awal (current user ID & status follow) ---
  Future<void> _loadInitialData() async {
    // Ambil ID pengguna yang saat ini login dari secure storage
    final id = await SecureStorage.getUserId();
    // Cek status follow awal terhadap pembuat post
    final initialFollowStatus = await _followService.isFollowing(widget.post.user.username);

    // Pastikan widget masih ada di tree sebelum update state
    if (mounted) {
      setState(() {
        _currentUserId = id;
        _isFollowing = initialFollowStatus;
      });
    }
  }


  void _setupExistingController() {
    _controller = widget.preInitializedController!;
    setState(() => _isInitialized = true);

    if (_hasMusic) {
      _audioPlayer.setSourceUrl(widget.post.musicPreviewUrl!);
      _controller!.addListener(_videoLoopListener);
    }

    if (widget.isActive) {
      _controller!.setLooping(true);
      if (_controller!.value.isPlaying) {
        if (_hasMusic) {
          _audioPlayer.resume();
        }
      } else {
        _controller!.play();
        if (_hasMusic) {
          _audioPlayer.resume();
        }
      }
    }
  }

  Future<void> _initializeNewController() async {
    final fileInfo =
    await VideoCacheService().getSingleFile(widget.post.mediaUrl!);
    if (mounted) {
      _controller = VideoPlayerController.file(fileInfo.file)
        ..initialize().then((_) {
          if (mounted) {
            if (_hasMusic) {
              _controller!.setVolume(0.0);
              _audioPlayer.setSourceUrl(widget.post.musicPreviewUrl!);
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
    }
  }

  void _videoLoopListener() {
    if (_controller == null || !_controller!.value.isInitialized || !_hasMusic)
      return;

    final currentPosition = _controller!.value.position;

    if (currentPosition < _lastPosition) {
      _audioPlayer.seek(Duration.zero);
      if (_controller!.value.isPlaying) {
        _audioPlayer.resume();
      }
    }
    _lastPosition = currentPosition;
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoLoopListener);
    if (widget.preInitializedController == null) {
      _controller?.dispose();
    }
    _audioPlayer.dispose();
    _pauseIconAnimationController.dispose();
    super.dispose();
  }

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

        setState(() => _showPauseIcon = true);
        _pauseIconAnimationController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _pauseIconAnimationController.reverse().then((_) {
                if (mounted) {
                  setState(() => _showPauseIcon = false);
                }
              });
            }
          });
        });
      } else {
        _controller!.play();
        if (_hasMusic) _audioPlayer.resume();

        if (_showPauseIcon) {
          _pauseIconAnimationController.reverse();
          setState(() => _showPauseIcon = false);
        }
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

  // --- 5. PERUBAHAN: Implementasi penuh fungsi follow/unfollow ---
  void _toggleFollow() async {
    final bool originalFollowStatus = _isFollowing;

    // Optimistic UI update
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      bool success;
      // Gunakan user ID jika tersedia, jika tidak, gunakan username sebagai fallback
      final userIdentifier = widget.post.user.id ?? widget.post.user.username;

      if (_isFollowing) {
        // Jika state baru adalah 'mengikuti', panggil service follow
        success = await _followService.followUser(userIdentifier);
      } else {
        // Jika state baru adalah 'tidak mengikuti', panggil service unfollow
        success = await _followService.unfollowUser(userIdentifier);
      }

      // Jika aksi dari API gagal, kembalikan state ke semula
      if (!success && mounted) {
        setState(() {
          _isFollowing = originalFollowStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aksi gagal, coba lagi.')),
        );
      }
    } catch (e) {
      // Jika terjadi error, kembalikan juga state ke semula
      if (mounted) {
        setState(() {
          _isFollowing = originalFollowStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
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
        child:
        const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                ),
              _buildOverlayUI(),
              if (value.isBuffering)
                const CircularProgressIndicator(color: Colors.white),
              if (_showPauseIcon)
                FadeTransition(
                  opacity: _pauseIconAnimation,
                  child: ScaleTransition(
                    scale: _pauseIconAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Icons.pause, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              Positioned(
                bottom: 85.0 + 10.0,
                left: 0,
                right: 0,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12.0),
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
                        _sliderPosition =
                            Duration(milliseconds: newValue.round());
                      });
                    },
                    onChangeEnd: (newValue) {
                      final newPosition =
                      Duration(milliseconds: newValue.round());
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
          padding: const EdgeInsets.only(bottom: 90.0 + 10.0),
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
          const Text('Clips',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool hasMusic = widget.post.musicTrackName != null &&
        widget.post.musicTrackName!.isNotEmpty;
    final String audioText = hasMusic
        ? '${widget.post.musicTrackName!} - ${widget.post.musicArtistName ?? 'Sounds'}'
        : 'Original audio - ${widget.post.user.username}';

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularAvatarFetcher(
                      radius: 12,
                      userId: widget.post.user.id ?? 0,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.user.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    if (widget.post.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 14),
                    ],
                    // --- 6. PERUBAHAN: Kondisi untuk menampilkan tombol follow ---
                    // Tampilkan hanya jika _currentUserId sudah terisi DAN ID pembuat post tidak sama dengan _currentUserId
                    if (_currentUserId != null && widget.post.user.id != _currentUserId)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: _toggleFollow, // Panggil fungsi yang sudah diimplementasikan
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? Colors.white.withOpacity(0.3)
                                  : Color(0xFFFF9100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isFollowing ? 'Mengikuti' : 'Ikuti',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.post.caption != null &&
                    widget.post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 20,
                        child: Marquee(
                          text: audioText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 20.0,
                          velocity: 50.0,
                          pauseAfterRound: const Duration(seconds: 1),
                        ),
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
              _buildLikeButton(),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.comment,
                label: '$_commentsCount',
                onTap: () => _showCommentSheet(context),
                size: 32,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                onTap: _toggleBookmark,
                iconColor: _isBookmarked ? Colors.orangeAccent : Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              _buildActionButton(icon: Icons.share, size: 32),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('Thumbnail video diklik!')));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: widget.post.mediaUrl != null && widget.post.isVideo
                        ? CachedNetworkImage(
                      imageUrl: widget.post.mediaUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                          child: Icon(Icons.videocam_outlined, color: Colors.white, size: 24)),
                      errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white, size: 24)),
                    )
                        : const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 24)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    final likers = widget.post.recentLikers;
    final displayedLikers = likers.take(3).toList().reversed.toList();

    return GestureDetector(
      onTap: _toggleLike,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          if (displayedLikers.isNotEmpty)
            SizedBox(
              height: 28,
              width: 50,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(displayedLikers.length, (index) {
                  final liker = displayedLikers[index];
                  return Positioned(
                    left: (index * 15.0),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: liker.profilePictureUrl != null
                            ? NetworkImage(liker.profilePictureUrl!)
                            : null,
                        child: liker.profilePictureUrl == null
                            ? const Icon(Icons.person,
                            size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            '$_likesCount',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        String? label,
        VoidCallback? onTap,
        Color? iconColor,
        double size = 32}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? Colors.white, size: size),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}