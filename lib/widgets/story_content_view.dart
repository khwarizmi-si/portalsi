// lib/widgets/story_content_view.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' hide AudioPlayer;
import 'package:video_player/video_player.dart';
import '../controllers/story_content_controller.dart';
import '../models/story_model.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget utama yang berfungsi sebagai router untuk menampilkan
/// tipe konten story yang sesuai (Gambar, Video, atau Musik).
class StoryContentView extends StatefulWidget {
  final StoryDetail story;
  final AnimationController progressController;
  final StoryContentController controller;
  final Function(Duration) onContentLoaded;

  const StoryContentView({
    Key? key,
    required this.story,
    required this.progressController,
    required this.controller,
    required this.onContentLoaded,
  }) : super(key: key);

  @override
  _StoryContentViewState createState() => _StoryContentViewState();
}

class _StoryContentViewState extends State<StoryContentView> {
  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo && widget.story.mediaUrl != null) {
      return _VideoPlayerContent(
        story: widget.story,
        controller: widget.controller,
        onContentLoaded: widget.onContentLoaded,
      );
    } else if (widget.story.isMusicStory) {
      return _MusicContent(
        story: widget.story,
        controller: widget.controller,
        progressController: widget.progressController,
        onContentLoaded: widget.onContentLoaded,
      );
    } else {
      return _ImageContent(
        story: widget.story,
        onContentLoaded: widget.onContentLoaded,
      );
    }
  }
}

// --- KONTEN GAMBAR ---
class _ImageContent extends StatefulWidget {
  final StoryDetail story;
  final Function(Duration) onContentLoaded;

  const _ImageContent({
    required this.story,
    required this.onContentLoaded,
  });

  @override
  _ImageContentState createState() => _ImageContentState();
}

class _ImageContentState extends State<_ImageContent> {
  late ImageStream _imageStream;
  late ImageStreamListener _imageListener;
  bool _isImageReady = false;

  @override
  void initState() {
    super.initState();
    final imageProvider = NetworkImage(widget.story.mediaUrl!);

    _imageListener = ImageStreamListener(
          (imageInfo, synchronousCall) {
        if (mounted) {
          // --- 👇 PERBAIKAN DI SINI 👇 ---
          // Tunda panggilan ini sampai setelah frame selesai di-build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isImageReady = true;
              });
              widget.onContentLoaded(const Duration(seconds: 5));
            }
          });
        }
      },
    );

    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageStream.addListener(_imageListener);
  }

  @override
  void dispose() {
    // 6. Jangan lupa hapus listener untuk mencegah memory leak
    _imageStream.removeListener(_imageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isImageReady) {
      return Container(
        // color: Colors.black, <-- HAPUS BARIS INI
        decoration: BoxDecoration(
          // --- 👇 PINDAHKAN WARNA KE DALAM SINI 👇 ---
          color: Colors.black,
          image: DecorationImage(
            image: NetworkImage(widget.story.mediaUrl!),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      // Biarkan yang ini seperti sebelumnya, sudah benar
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
  }
}

// --- KONTEN VIDEO ---
class _VideoPlayerContent extends StatefulWidget {
  final StoryDetail story;
  final StoryContentController controller;
  final Function(Duration) onContentLoaded;

  const _VideoPlayerContent({
    required this.story,
    required this.controller,
    required this.onContentLoaded,
  });

  @override
  _VideoPlayerContentState createState() => _VideoPlayerContentState();
}

class _VideoPlayerContentState extends State<_VideoPlayerContent> {
  VideoPlayerController? _videoController;
  bool _isContentReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.story.mediaUrl!))
        ..initialize().then((_) {
          if (!mounted) return;

          setState(() {
            _isContentReady = true;
          });

          final controller = _videoController;
          if (controller != null && controller.value.isInitialized) {
            // Kirim durasi asli video ke parent widget
            widget.onContentLoaded(controller.value.duration);
          }
        });

      widget.controller.addListeners(
        onPause: () => _videoController?.pause(),
        onResume: () => _videoController?.play(),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isContentReady && _videoController!.value.isInitialized) {
      // --- 👇 BUNGKUS DENGAN CONTAINER BARU 👇 ---
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }
    // Beri juga latar belakang hitam saat loading
    return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white))
    );
  }
}


// --- KONTEN MUSIK ---
class _MusicContent extends StatefulWidget {
  final StoryDetail story;
  final StoryContentController controller;
  final AnimationController progressController;
  final Function(Duration) onContentLoaded;

  const _MusicContent({
    required this.story,
    required this.controller,
    required this.progressController,
    required this.onContentLoaded,
  });

  @override
  _MusicContentState createState() => _MusicContentState();
}

class _MusicContentState extends State<_MusicContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _audioPositionSubscription;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Listener untuk pause/resume (sudah sesuai dengan API baru)
    widget.controller.addListeners(
      onPause: () {
        _vinylController.stop();
        _audioPlayer.pause();
      },
      onResume: () {
        _vinylController.repeat();
        _audioPlayer.resume(); // Method resume() ada di versi terbaru
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final duration =
        Duration(milliseconds: widget.story.musicClipDurationMs ?? 15000);
        widget.onContentLoaded(duration);
        _playMusicClip();
      }
    });
  }

  void _playMusicClip() async {
    final story = widget.story;
    if (story.musicPreviewUrl == null) return;

    try {
      final startPosition =
      Duration(milliseconds: story.musicStartPositionMs ?? 0);
      final clipDuration =
      Duration(milliseconds: story.musicClipDurationMs ?? 15000);

      // --- SINTAKS API VERSI TERBARU (v5+) ---
      // 1. Menggunakan 'UrlSource' untuk membungkus URL
      await _audioPlayer.play(UrlSource(story.musicPreviewUrl!));
      // 2. 'seek' dipanggil setelah 'play' untuk mengatur posisi awal
      await _audioPlayer.seek(startPosition);

      // 3. Gunakan 'onPositionChanged'
      _audioPositionSubscription =
          _audioPlayer.onPositionChanged.listen((position) {
            if (position >= startPosition + clipDuration) {
              _audioPlayer.seek(startPosition);
            }
          });
      // --- BATAS SINTAKS BARU ---

    } catch (e) {
      print("Gagal memutar audio cerita musik: $e");
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _audioPositionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.story.musicAlbumArtUrl ?? widget.story.mediaUrl;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (imageUrl != null)
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        // Placeholder untuk UI Musik
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _vinylController,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: imageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.story.musicTrackName ?? 'Unknown Track',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.story.musicArtistName ?? 'Unknown Artist',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ],
        )
      ],
    );
  }
}