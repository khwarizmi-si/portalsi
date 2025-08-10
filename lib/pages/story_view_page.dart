// lib/pages/story_view_page.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../widgets/story_content_view.dart';
import 'package:page_transition/page_transition.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';

class StoryViewPage extends StatefulWidget {
  final UserWithStories userWithStories;
  final String heroTag;
  final List<UserWithStories>? nextStories;
  final List<UserWithStories>? previousStories;

  const StoryViewPage({
    Key? key,
    required this.userWithStories,
    required this.heroTag,
    this.nextStories,
    this.previousStories,
  }) : super(key: key);

  @override
  _StoryViewPageState createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  bool _isLoadingContent = true;
  double _scale = 1.0;
  double _opacity = 1.0;

  // --- LOGIKA BARU UNTUK MUSIK (DISALIN DARI MY_STORY_VIEW_PAGE) ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _vinylController;
  Timer? _playbackTimer;
  late List<StoryDetail> _stories; // Gunakan list lokal

  @override
  void initState() {
    super.initState();
    _stories = List.of(widget.userWithStories.stories); // Salin list
    _pageController = PageController();
    _progressController = AnimationController(vsync: this);
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    if (_stories.isNotEmpty) {
      _loadStoryAndStartTimer(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressController.stop();
        _progressController.reset();
        _nextStory();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    _audioPlayer.dispose(); // Jangan lupa dispose audio player
    _vinylController.dispose();
    _playbackTimer?.cancel();
    super.dispose();
  }

  // --- FUNGSI INI DIMODIFIKASI TOTAL UNTUK MENANGANI MUSIK ---
  Future<void> _loadStoryAndStartTimer(int index) async {
    if (_stories.isEmpty || index < 0 || index >= _stories.length) return;

    setState(() {
      _isLoadingContent = true;
      _currentIndex = index;
    });
    _progressController.stop();
    _progressController.reset();

    // Hentikan semua media player sebelumnya
    await _videoController?.dispose();
    _videoController = null;
    await _audioPlayer.stop();
    _playbackTimer?.cancel();

    final StoryDetail story = _stories[index];

    if (story.isMusicStory) {
      // LOGIKA UNTUK CERITA MUSIK
      final position = Duration(milliseconds: story.musicStartPositionMs ?? 0);
      await _audioPlayer.play(UrlSource(story.musicPreviewUrl!), position: position);

      _playbackTimer = Timer(const Duration(seconds: 15), () {
        if(mounted) _audioPlayer.stop();
      });

      _progressController.duration = const Duration(seconds: 15);

    } else if (story.isVideo) {
      // LOGIKA UNTUK VIDEO
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      await _videoController!.initialize();
      if (mounted) {
        _progressController.duration = _videoController!.value.duration;
        _videoController!.play();
      }
    } else {
      // LOGIKA UNTUK GAMBAR
      await precacheImage(NetworkImage(story.mediaUrl), context);
      if (mounted) {
        _progressController.duration = const Duration(seconds: 5);
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingContent = false;
      });
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      final nextIndex = _currentIndex + 1;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
      _loadStoryAndStartTimer(nextIndex);
    } else {
      if (widget.nextStories != null && widget.nextStories!.isNotEmpty) {
        final nextUserData = widget.nextStories!.first;
        final remainingQueue = widget.nextStories!.sublist(1);
        final newPrevQueue = [...?widget.previousStories, widget.userWithStories];

        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftPop,
            child: StoryViewPage(
              userWithStories: nextUserData,
              heroTag: 'story_hero_${nextUserData.userId}',
              previousStories: newPrevQueue,
              nextStories: remainingQueue,
            ),
            childCurrent: widget,
            duration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      _pageController.animateToPage(prevIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
      _loadStoryAndStartTimer(prevIndex);
    } else {
      if (widget.previousStories != null && widget.previousStories!.isNotEmpty) {
        final previousUserData = widget.previousStories!.last;
        final remainingPrevQueue = widget.previousStories!.sublist(0, widget.previousStories!.length - 1);
        final newNextQueue = [widget.userWithStories, ...?widget.nextStories];

        Navigator.pushReplacement(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightPop,
              child: StoryViewPage(
                userWithStories: previousUserData,
                heroTag: 'story_hero_${previousUserData.userId}',
                previousStories: remainingPrevQueue,
                nextStories: newNextQueue,
              ),
              childCurrent: widget,
              duration: const Duration(milliseconds: 600)
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) {
      return '${duration.inDays} hari yang lalu';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam yang lalu';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final StoryDetail currentStory = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Dismissible(
        key: const Key('story-view-dismissible'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.of(context).pop(),
        onUpdate: (details) {
          setState(() {
            _scale = 1 - (details.progress * 0.2);
            _opacity = 1 - (details.progress * 0.5);
          });
        },
        child: Opacity(
          opacity: _opacity,
          child: Transform.scale(
            scale: _scale,
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTapUp: (details) {
                  if (_isLoadingContent) return;
                  final double screenWidth = MediaQuery.of(context).size.width;
                  final double dx = details.globalPosition.dx;
                  if (dx < screenWidth / 3) {
                    _previousStory();
                  } else if (dx > screenWidth * 2 / 3) {
                    _nextStory();
                  }
                },
                onLongPressStart: (_) => _progressController.stop(),
                onLongPressEnd: (_) => _progressController.forward(),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stories.length,
                        itemBuilder: (context, index) {
                          final story = _stories[index];
                          // --- CUKUP PANGGIL STORYCONTENTVIEW ---
                          return Hero(
                            tag: widget.heroTag,
                            child: StoryContentView(
                              key: ValueKey(story.storyId), // Key agar widget di-rebuild saat ganti cerita
                              story: story,
                              progressController: _progressController,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 40.0,
                        left: 10.0,
                        right: 10.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: _stories.asMap().entries.map((entry) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (context, child) {
                                        return LinearProgressIndicator(
                                          value: entry.key == _currentIndex
                                              ? _progressController.value
                                              : (entry.key < _currentIndex ? 1.0 : 0.0),
                                          backgroundColor: Colors.grey[800],
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(widget.userWithStories.profilePictureUrl),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userWithStories.username,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      _formatTimeAgo(currentStory.createdAt),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (currentStory.caption.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    currentStory.caption,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Kirim pesan...',
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          filled: false,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: const BorderSide(color: Colors.white, width: 2),
                                          ),
                                        ),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28)),
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.send_outlined, color: Colors.white, size: 28)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoadingContent)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicStoryView(StoryDetail story) {
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