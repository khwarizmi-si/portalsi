// lib/widgets/story_content_view.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/story_content_controller.dart';
import '../models/story_model.dart';
import '../pages/my_story_view_page.dart';

class StoryContentView extends StatefulWidget {
  final StoryDetail story;
  final AnimationController progressController;
  final VoidCallback onContentLoaded;
  final StoryContentController controller;

  const StoryContentView({
    Key? key,
    required this.story,
    required this.progressController,
    required this.onContentLoaded,
    required this.controller,
  }) : super(key: key);

  @override
  _StoryContentViewState createState() => _StoryContentViewState();
}

class _StoryContentViewState extends State<StoryContentView> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _vinylController;
  StreamSubscription? _audioPositionSubscription;

  bool _isContentReady = false;

  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isSheetOpen = false;
  bool _isLongPressing = false;

  final Map<int, StoryContentController> _contentControllers = {};
  // Map untuk mengelola state zoom setiap story
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    widget.controller.addListeners(
      onPause: () {
        if (!mounted) return;
        _videoController?.pause();
        _audioPlayer.pause();
        _vinylController.stop();
      },
      onResume: () {
        if (!mounted) return;
        _videoController?.play();
        _audioPlayer.resume();
        _vinylController.repeat();
      },
    );

    _loadContent();
  }

  @override
  void didUpdateWidget(covariant StoryContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.story.storyId != oldWidget.story.storyId) {
      _resetAndLoadContent();
    }
  }

  void _resetAndLoadContent() {
    setState(() {
      _isContentReady = false;
    });

    widget.progressController.stop();
    widget.progressController.reset();
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer.stop();
    _audioPositionSubscription?.cancel();
    _vinylController.stop();
    _loadContent();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    _videoController?.dispose();
    _audioPlayer.dispose();
    _vinylController.dispose();
    _audioPositionSubscription?.cancel();
    super.dispose();
  }

  // MODIFIKASI UTAMA: Alur pemuatan diubah menjadi sekuensial
  Future<void> _loadContent() async {
    if (!mounted) return;

    final story = widget.story;
    Duration contentDuration = const Duration(seconds: 5);

    // TAHAP 1: Memuat Aset Visual (Gambar atau Video) Terlebih Dahulu
    final visualCompleter = Completer<void>();

    if (story.isVideo && story.mediaUrl != null) {
      // Pemuatan Video
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!));
      await _videoController!.initialize();
      contentDuration = _videoController!.value.duration;
      visualCompleter.complete();
    } else {
      // Pemuatan Gambar (baik untuk story gambar maupun background musik)
      final imageUrl = story.mediaUrl ?? story.musicAlbumArtUrl;
      if (imageUrl != null) {
        final imageProvider = NetworkImage(imageUrl);
        final stream = imageProvider.resolve(const ImageConfiguration());
        late ImageStreamListener listener;
        listener = ImageStreamListener(
              (ImageInfo image, bool sync) {
            if (!visualCompleter.isCompleted) visualCompleter.complete();
            stream.removeListener(listener);
          },
          onError: (dynamic e, StackTrace? s) {
            print("Error loading image: $e");
            if (!visualCompleter.isCompleted) visualCompleter.complete();
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
      } else {
        // Jika tidak ada aset visual sama sekali
        visualCompleter.complete();
      }
    }

    // Menunggu hingga aset visual benar-benar siap
    await visualCompleter.future;

    // TAHAP 2: Setelah visual siap, BARU putar audio jika ada
    if (mounted && story.isMusicStory && story.musicPreviewUrl != null) {
      contentDuration = Duration(milliseconds: story.musicClipDurationMs ?? 15000);
      final position = Duration(milliseconds: story.musicStartPositionMs ?? 0);

      await _audioPlayer.play(UrlSource(story.musicPreviewUrl!), position: position);

      _audioPositionSubscription = _audioPlayer.onPositionChanged.listen((currentPosition) {
        if (currentPosition >= position + contentDuration) {
          _audioPlayer.seek(position);
        }
      });
    }

    // TAHAP 3: Setelah semua siap, update UI dan mulai media
    if (mounted) {
      setState(() {
        _isContentReady = true;
      });

      // Mulai media yang sesuai
      _videoController?.play();
      if (story.isMusicStory) {
        _vinylController.repeat();
      }

      widget.progressController.duration = contentDuration;
      widget.onContentLoaded(); // Sinyal dikirim untuk memulai timer
    }
  }

  void _pauseStory() {
    // 1. Menghentikan timer progress bar di bagian atas.
    _progressController.stop();

    // 2. Mengirim perintah 'pause' ke widget StoryContentView yang sedang aktif.
    //    Tanda tanya (?) memastikan kode tidak error jika controller tidak ada.
    _contentControllers[_currentIndex]?.pause();
  }

  void _resumeStory() {
    // Lakukan pengecekan sebelum melanjutkan story:
    if (mounted && !_isSheetOpen && !_isLongPressing) {

      // Cek tambahan: Apakah story sedang di-zoom?
      final currentScale = _transformationControllers[_currentIndex]?.value.getMaxScaleOnAxis() ?? 1.0;

      // Hanya lanjutkan jika semua kondisi terpenuhi (tidak ada sheet, tidak ditahan, dan tidak di-zoom).
      if (currentScale <= 1.0) {
        // 1. Melanjutkan kembali timer progress bar.
        _progressController.forward();

        // 2. Mengirim perintah 'resume' ke StoryContentView untuk melanjutkan video/audio.
        _contentControllers[_currentIndex]?.resume();
      }
    }
  }

  void _showAudioDetailsSheet(BuildContext context, StoryDetail story) {
    widget.controller.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return _AudioDetailsSheet(story: story, scrollController: scrollController);
          },
        );
      },
    ).whenComplete(() {
      // 2. Setelah sheet ditutup, tandai bahwa sheet sudah tidak ada
      //    dan PANGGIL FUNGSI LANJUTKAN UTAMA
      setState(() => _isSheetOpen = false);
      _resumeStory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Hanya tampilkan visual jika sudah siap
        if (_isContentReady) _buildVisualMedia(widget.story),

        // Hanya tampilkan stiker musik jika sudah siap
        if (_isContentReady && widget.story.isMusicStory) _buildMusicOverlay(widget.story),

        // Tampilkan loading indicator selama proses pemuatan
        if (!_isContentReady)
          Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildVisualMedia(StoryDetail story) {
    if (story.isMusicStory && story.mediaUrl == null) {
      final String albumArtUrl = story.musicAlbumArtUrl ?? 'https://via.placeholder.com/400';
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(albumArtUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ],
      );
    }

    if (story.mediaUrl != null) {
      if (story.isVideo) {
        return (_videoController?.value.isInitialized ?? false)
            ? Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)))
            : Container(color: Colors.black);
      }
      return Image.network(story.mediaUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    return Container(color: Colors.black);
  }

  Widget _buildMusicOverlay(StoryDetail story) {
    final String style = story.musicDisplayStyle ?? 'vinyl';
    final double? relativeX = story.musicStickerPositionX;
    final double? relativeY = story.musicStickerPositionY;

    Widget musicWidget;

    switch (style) {
      case 'largeCard':
        musicWidget = _buildLargeMusicCard(story);
        break;
      case 'smallCard':
        musicWidget = _buildSmallMusicCard(story);
        break;
      default:
        musicWidget = _buildVinylPreview(story);
    }

    if (style != 'vinyl' && relativeX != null && relativeY != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double absoluteX = relativeX * constraints.maxWidth;
          final double absoluteY = relativeY * constraints.maxHeight;

          // [FIX] Buat Stack baru di dalam LayoutBuilder
          return Stack(
            children: [
              // Sekarang, Positioned adalah anak langsung dari Stack
              Positioned(
                left: absoluteX,
                top: absoluteY,
                child: musicWidget,
              ),
            ],
          );
        },
      );
    }

    return Center(child: musicWidget);
  }

  Widget _buildVinylPreview(StoryDetail story) {
    return GestureDetector(
      onTap: () => _showAudioDetailsSheet(context, story),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _vinylController,
            child: Container(
              width: 280, height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: NetworkImage('https://i.imgur.com/HgflQqA.png')),
              ),
              child: Center(
                child: ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size.fromRadius(100),
                    child: Image.network(story.musicAlbumArtUrl ?? 'https://via.placeholder.com/150', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(story.musicTrackName ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)])),
          const SizedBox(height: 4),
          Text(story.musicArtistName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16, shadows: [Shadow(blurRadius: 4)])),
        ],
      ),
    );
  }

  Widget _buildLargeMusicCard(StoryDetail story) {
    return GestureDetector(
      onTap: () => _showAudioDetailsSheet(context, story),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(story.musicAlbumArtUrl ?? 'https://via.placeholder.com/150', width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.equalizer, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    story.musicTrackName ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    story.musicArtistName ?? '',
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMusicCard(StoryDetail story) {
    return GestureDetector(
      onTap: () => _showAudioDetailsSheet(context, story),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(story.musicAlbumArtUrl ?? 'https://via.placeholder.com/150', width: 24, height: 24, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.equalizer, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${story.musicTrackName ?? ''} • ${story.musicArtistName ?? ''}',
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioDetailsSheet extends StatelessWidget {
  final StoryDetail story;
  final ScrollController scrollController;

  const _AudioDetailsSheet({
    Key? key,
    required this.story,
    required this.scrollController
  }) : super(key: key);

  final List<Map<String, dynamic>> reelsGridData = const [
    {'views': 302, 'imageUrl': 'https://i.pravatar.cc/300?img=15'},
    {'views': 2449, 'imageUrl': 'https://i.pravatar.cc/300?img=16'},
    {'views': 145, 'imageUrl': 'https://i.pravatar.cc/300?img=17'},
    {'views': 876, 'imageUrl': 'https://i.pravatar.cc/300?img=18'},
    {'views': 5123, 'imageUrl': 'https://i.pravatar.cc/300?img=19'},
    {'views': 98, 'imageUrl': 'https://i.pravatar.cc/300?img=20'},
    {'views': 750, 'imageUrl': 'https://i.pravatar.cc/300?img=21'},
    {'views': 1234, 'imageUrl': 'https://i.pravatar.cc/300?img=22'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            story.musicAlbumArtUrl ?? 'https://via.placeholder.com/150',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.trending_up, color: Colors.white70, size: 18),
                                  SizedBox(width: 4),
                                  Text('Trending', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              SizedBox(
                                height: 48,
                                width: 48,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                          Text(
                            story.musicTrackName ?? 'Unknown Track',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            story.musicArtistName ?? 'Unknown Artist',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Text('0:30 · ${54} reels', style: const TextStyle(color: Colors.white70)),
                    // const Spacer(),
                    // const Icon(Icons.music_note, color: Colors.green, size: 20),
                    // const SizedBox(width: 4),
                    // const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    // const SizedBox(width: 16),
                    // const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
                    // const SizedBox(width: 16),
                    // const Icon(Icons.send_outlined, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                // ElevatedButton(
                //   onPressed: () {},
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blueAccent,
                //     padding: const EdgeInsets.symmetric(vertical: 14),
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                //   ),
                //   child:
                //   const Text('Use audio', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                //   ),
                // ),
                const SizedBox(height: 16),
                // GridView.builder(
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                //     crossAxisCount: 3,
                //     crossAxisSpacing: 4,
                //     mainAxisSpacing: 4,
                //     childAspectRatio: 9 / 16,
                //   ),
                //   itemCount: reelsGridData.length,
                //   itemBuilder: (context, index) {
                //     final reel = reelsGridData[index];
                //     return Stack(
                //       fit: StackFit.expand,
                //       children: [
                //         Image.network(reel['imageUrl'], fit: BoxFit.cover),
                //         Positioned(
                //           bottom: 8,
                //           left: 8,
                //           child: Row(
                //             children: [
                //               const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                //               const SizedBox(width: 4),
                //               Text(
                //                 reel['views'].toString(),
                //                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)]),
                //               ),
                //             ],
                //           ),
                //         )
                //       ],
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}