import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:portal_si/components/post_action_counts.dart';
import 'package:portal_si/components/post_info_section.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:portal_si/components/post_header.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/pages/clips_viewer_page.dart';

import '../utils/global_audio_state.dart';

// --- WIDGET BARU UNTUK TAMPILAN ZOOM GAMBAR ---
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! > 10) {
                Navigator.of(context).pop();
              }
            },
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback? onProfileTap;
  final bool hasCardDecoration;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
    required this.onComment,
    this.onProfileTap,
    this.hasCardDecoration = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _wasPlayingBeforeHold = false;
  bool _videoEnded = false;
  late final AudioPlayer _audioPlayer;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  bool _isHeartVisible = false;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkScaleAnimation;
  bool _musicPlaybackAllowed = false;
  bool _showContinueWatchingOverlay = false;

  bool _isAppInForeground = true;
  bool _isWidgetVisible = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
    _initAudioPlayer();

    // (3) Daftarkan observer untuk lifecycle aplikasi
    WidgetsBinding.instance.addObserver(this);

    GlobalAudioState.instance.addListener(_onGlobalMuteStateChanged);

    _bookmarkAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _bookmarkAnimationController, curve: Curves.elasticOut));
    _heartAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartAnimationController, curve: Curves.easeOut));
    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isHeartVisible = false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      // Putar kembali jika widget terlihat saat kembali ke aplikasi
      _handleAudioPlaybackState();
    } else {
      // App di background atau tidak aktif, pause semua media
      _isAppInForeground = false;
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      }
      if (_videoController?.value.isPlaying ?? false) {
        _videoController?.pause();
      }
    }
  }

  // (3) Helper baru untuk mengelola pemutaran audio
  void _handleAudioPlaybackState() {
    if (_audioPlayer.audioSource == null || widget.post.isVideo) return;

    if (_isAppInForeground && _isWidgetVisible) {
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    } else {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      }
    }
  }

  void _navigateToClipsViewer() {
    // Tidak perlu pause di sini, karena controller akan terus digunakan
    // di halaman selanjutnya. Biarkan statusnya apa adanya (playing/paused).
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClipsViewerPage(
          initialClip: widget.post,
          // --- INTI PERUBAHAN: Kirim controller yang aktif ---
          existingController: _videoController,
        ),
      ),
    ).then((_) {
      // Kode ini akan berjalan saat pengguna kembali dari ClipsViewerPage.
      // Kita perlu memastikan video di PostCard tidak otomatis berputar
      // jika tidak terlihat. VisibilityDetector akan menanganinya.
      if (mounted) {
        setState(() {}); // Memaksa refresh UI jika perlu (misal: update ikon mute)
      }
    });
  }

  void _onGlobalMuteStateChanged() {
    final isMuted = GlobalAudioState.instance.isMuted;

    // Terapkan status mute ke semua player
    _audioPlayer.setVolume(isMuted ? 0.0 : 1.0);

    final bool hasMusic = widget.post.musicPreviewUrl != null && widget.post.musicPreviewUrl!.isNotEmpty;
    if (_videoController != null && !hasMusic) {
      _videoController!.setVolume(isMuted ? 0.0 : 1.0);
    }

    // Panggil setState agar UI (seperti ikon mute) ikut diperbarui
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    final musicUrl = widget.post.musicPreviewUrl;
    if (musicUrl != null && musicUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(musicUrl);
        await _audioPlayer.setLoopMode(LoopMode.one);
        // Atur volume awal berdasarkan state global saat ini
        _audioPlayer.setVolume(GlobalAudioState.instance.isMuted ? 0.0 : 1.0);
      } catch (e) {
        print("Error loading audio source: $e");
      }
    }
  }

  @override
  void dispose() {
    // (3) Hapus observer
    WidgetsBinding.instance.removeObserver(this);
    GlobalAudioState.instance.removeListener(_onGlobalMuteStateChanged);

    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _audioPlayer.dispose();
    _bookmarkAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      _videoController?.removeListener(_videoListener);
      _videoController?.dispose();
      _videoController = null;
      _audioPlayer.dispose();
      _initVideoPlayer();
      _initAudioPlayer();
    }
  }

  void _openImageZoom(BuildContext context) {
    if (widget.post.isVideo || widget.post.mediaUrl == null || widget.post.mediaUrl!.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return _FullScreenImageViewer(
            imageUrl: widget.post.mediaUrl!,
            heroTag: 'post-image-hero-${widget.post.id}',
          );
        },
      ),
    );
  }

  void _onBookmarkTap() {
    widget.onBookmark();
    _bookmarkAnimationController.forward().then((_) => _bookmarkAnimationController.reverse());
  }

  void _onDoubleTap() {
    if (!widget.post.isLikedByUser) {
      widget.onLike();
    }
    setState(() => _isHeartVisible = true);
    _heartAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post-card-${widget.post.id}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.6;
        _isWidgetVisible = isVisible; // (3) Update status visibilitas widget

        // Logika untuk Video Player
        if (_videoController != null && _videoController!.value.isInitialized && !_videoEnded && !_showContinueWatchingOverlay) {
          if (isVisible && _isAppInForeground) {
            if (!_videoController!.value.isPlaying) _videoController!.play();
          } else {
            if (_videoController!.value.isPlaying) _videoController!.pause();
          }
        }
        // Logika untuk Audio Player di post gambar
        else if (!widget.post.isVideo) {
          _handleAudioPlaybackState(); // (3) Gunakan helper baru
        }
      },
      child: Container(
        margin: widget.hasCardDecoration ? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0) : EdgeInsets.zero,
        decoration: widget.hasCardDecoration ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, width: 0.5)) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(12), child: PostHeader(post: widget.post, onProfileTap: widget.onProfileTap)),
            if (widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty) _buildMediaWidget(),
            _buildMusicInfo(),
            PostActionCounts(post: widget.post, onLike: widget.onLike, onComment: widget.onComment, onShare: widget.onShare, onBookmark: _onBookmarkTap),
            PostInfoSection(post: widget.post),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicInfo() {
    final musicTrackName = widget.post.musicTrackName;
    if (musicTrackName == null || musicTrackName.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            const Icon(Icons.music_note, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 20,
                child: Marquee(
                  text: '${widget.post.musicTrackName} - ${widget.post.musicArtistName ?? 'Unknown Artist'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 20.0,
                  velocity: 50.0,
                  pauseAfterRound: const Duration(seconds: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaWidget() {
    Widget mediaContent;
    final heroTag = 'post-image-hero-${widget.post.id}';
    final bool hasMusic = widget.post.musicPreviewUrl != null && widget.post.musicPreviewUrl!.isNotEmpty;

    if (widget.post.isVideo) {
      mediaContent = FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _videoController != null && _videoController!.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            );
          }
          return AspectRatio(aspectRatio: 16.0 / 9.0, child: Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))));
        },
      );
    } else {
      mediaContent = Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          imageUrl: widget.post.mediaUrl!,
          placeholder: (context, url) => AspectRatio(aspectRatio: 1.0, child: Container(color: Colors.grey.shade200)),
          errorWidget: (context, url, error) => AspectRatio(aspectRatio: 1.0, child: Container(color: Colors.grey.shade200, child: Icon(Icons.broken_image, color: Colors.grey.shade400))),
        ),
      );
    }

    return ClipRRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            onTap: widget.post.isVideo ? _navigateToClipsViewer : () => _openImageZoom(context),
            child: mediaContent,
          ),
          if (widget.post.isVideo && !hasMusic)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: Icon(GlobalAudioState.instance.isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 18),
                ),
              ),
            ),
          if (hasMusic)
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: Icon(GlobalAudioState.instance.isMuted ? Icons.music_off_outlined : Icons.music_note_outlined, color: Colors.white, size: 18),
                ),
              ),
            ),
          if (_isHeartVisible)
            ScaleTransition(scale: _heartAnimation, child: const Icon(Icons.favorite, color: Colors.white, size: 80, shadows: [Shadow(color: Colors.black38, blurRadius: 12)])),
          if (_showContinueWatchingOverlay)
            _buildContinueWatchingOverlay(),

          if (_videoEnded && !_showContinueWatchingOverlay) // Pastikan hanya satu overlay yang tampil
            _buildReplayOverlay(),
        ],
      ),
    );
  }

  void _initVideoPlayer() {
    if (widget.post.isVideo && widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty) {
      // --- PERUBAHAN: Reset state overlay saat inisialisasi ---
      _videoEnded = false;
      _showContinueWatchingOverlay = false;

      _musicPlaybackAllowed = false;
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl!));

      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        final bool hasMusic = widget.post.musicPreviewUrl != null && widget.post.musicPreviewUrl!.isNotEmpty;
        _videoController!.setVolume(hasMusic ? 0.0 : (GlobalAudioState.instance.isMuted ? 0.0 : 1.0));

        if (mounted) {
          setState(() {});
        }
      });

      _videoController!.setLooping(false);
      _videoController!.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (_videoController == null || !_videoController!.value.isInitialized || !mounted) return;

    final position = _videoController!.value.position;
    final totalDuration = _videoController!.value.duration;

    // --- (1) PERBAIKAN UTAMA: Logika untuk memotong video ---
    final feedDurationLimit = const Duration(seconds: 25);
    // Cek durasi langsung dari controller untuk keandalan
    final bool isLongVideo = totalDuration > feedDurationLimit;

    if (isLongVideo && position >= feedDurationLimit && !_showContinueWatchingOverlay) {
      _videoController!.pause();
      if (_audioPlayer.playing) _audioPlayer.pause();
      setState(() {
        _showContinueWatchingOverlay = true;
      });
      return;
    }
    // --- AKHIR PERBAIKAN ---

    // --- (2) PERBAIKAN: Video di-pause saat selesai ---
    final bool isFinished = position >= totalDuration;
    if (isFinished && !_videoEnded) {
      _videoController!.pause(); // <-- TAMBAHAN PENTING
      if (_audioPlayer.playing) _audioPlayer.pause();
      setState(() => _videoEnded = true);
    }
    // --- AKHIR PERBAIKAN ---

    if (_musicPlaybackAllowed && _audioPlayer.audioSource != null) {
      if (_videoController!.value.isPlaying && !_audioPlayer.playing) {
        _audioPlayer.play();
      } else if (!_videoController!.value.isPlaying && _audioPlayer.playing) {
        _audioPlayer.pause();
      }
    }
  }

  void _toggleMute() {
    // Logika hanya membalik nilai di state global. Listener akan menangani sisanya.
    GlobalAudioState.instance.isMuted = !GlobalAudioState.instance.isMuted;
  }

  void _replayVideo() {
    if (_videoController == null) return;
    setState(() {
      _videoEnded = false;
      // --- PERUBAHAN: Reset juga state overlay saat replay ---
      _showContinueWatchingOverlay = false;
      _musicPlaybackAllowed = true;
    });

    _videoController!.seekTo(Duration.zero);
    _videoController!.play();

    if (_audioPlayer.audioSource != null) {
      _audioPlayer.seek(Duration.zero);
    }
  }

  // --- TAMBAHAN: Widget baru untuk overlay "Lanjutkan Menonton" ---
  Widget _buildContinueWatchingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Lanjutkan menonton',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.movie_filter_outlined, color: Colors.black, size: 20),
              label: const Text('Buka Clips', style: TextStyle(color: Colors.black)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _navigateToClipsViewer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplayOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Pemutaran selesai', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.replay, color: Colors.white, size: 20),
                  label: const Text('Putar Lagi', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _replayVideo,
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.movie_filter_outlined, color: Colors.black, size: 20),
                  label: const Text('Lainnya di Clips', style: TextStyle(color: Colors.black)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClipsViewerPage(initialClip: widget.post),
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}