// lib/widgets/story_content_view.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';

class StoryContentView extends StatefulWidget {
  final StoryDetail story;
  final AnimationController progressController; // Menerima controller dari parent

  const StoryContentView({
    Key? key,
    required this.story,
    required this.progressController,
  }) : super(key: key);

  @override
  _StoryContentViewState createState() => _StoryContentViewState();
}

class _StoryContentViewState extends State<StoryContentView> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _vinylController;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadContent();
  }

  @override
  void didUpdateWidget(covariant StoryContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.story.storyId != oldWidget.story.storyId) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _vinylController.dispose();
    _playbackTimer?.cancel();
    super.dispose();
  }

  Widget _buildVisualMedia(StoryDetail story) {
    if (story.isVideo) {
      return (_videoController?.value.isInitialized ?? false)
          ? Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)))
          : const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    // Untuk cerita musik, mediaUrl adalah album art, jadi ini akan jadi background
    return Image.network(story.mediaUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,);
  }

  Future<void> _loadContent() async {
    await _videoController?.dispose();
    _videoController = null;
    await _audioPlayer.stop();
    _playbackTimer?.cancel();

    final story = widget.story;

    if (story.isMusicStory) {
      final position = Duration(milliseconds: story.musicStartPositionMs ?? 0);
      await _audioPlayer.play(UrlSource(story.musicPreviewUrl!), position: position);

      _playbackTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) _audioPlayer.stop();
      });

      widget.progressController.duration = const Duration(seconds: 15);
    } else if (story.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      await _videoController!.initialize();
      if (mounted) {
        widget.progressController.duration = _videoController!.value.duration;
        _videoController!.play();
      }
    } else {
      widget.progressController.duration = const Duration(seconds: 5);
    }
    widget.progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN UTAMA: GUNAKAN STACK ---
    return Stack(
      alignment: Alignment.center,
      children: [
        // LAYER 1: Tampilkan media visual (gambar/video)
        // Media URL sekarang bisa jadi gambar biasa atau album art untuk cerita musik
        _buildVisualMedia(widget.story),

        // LAYER 2: Tampilkan stiker musik jika ada
        if (widget.story.isMusicStory)
          _buildMusicStoryView(widget.story),
      ],
    );
  }

  Widget _buildMusicStoryView(StoryDetail story) {
    // Di dunia nyata, Anda akan memiliki mapping dari string 'vinyl', 'largeCard' ke widget
    // Untuk saat ini, kita tampilkan UI default dari gambar.
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(story.mediaUrl, fit: BoxFit.cover),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _vinylController,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage('https://i.imgur.com/HgflQqA.png')),
                ),
                child: Center(
                  child: ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(100),
                      child: Image.network(story.mediaUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(story.musicTrackName ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(story.musicArtistName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}