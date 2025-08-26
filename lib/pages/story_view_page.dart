// lib/pages/story_view_page.dart

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import '../widgets/story_content_view.dart';
import '../models/story_model.dart';
import 'my_story_view_page.dart';

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

class _StoryViewPageState extends State<StoryViewPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  late List<StoryDetail> _stories;

  bool _isLongPressing = false;
  final Map<int, StoryContentController> _contentControllers = {};
  final Map<int, TransformationController> _transformationControllers = {};

  double _scale = 1.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _stories = List.of(widget.userWithStories.stories);
    _pageController = PageController();
    _progressController = AnimationController(vsync: this);

    if (_stories.isEmpty) {
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
    _contentControllers.forEach((_, controller) => controller.dispose());
    _transformationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _pauseStory() {
    _progressController.stop();
    _contentControllers[_currentIndex]?.pause();
  }

  void _resumeStory() {
    if (mounted && !_isLongPressing) {
      final currentScale = _transformationControllers[_currentIndex]?.value.getMaxScaleOnAxis() ?? 1.0;
      if (currentScale <= 1.0) {
        _progressController.forward();
        _contentControllers[_currentIndex]?.resume();
      }
    }
  }

  void _nextStory() {
    _transformationControllers[_currentIndex]?.value = Matrix4.identity();
    _contentControllers[_currentIndex]?.pause();

    if (_currentIndex < _stories.length - 1) {
      final nextIndex = _currentIndex + 1;
      setState(() => _currentIndex = nextIndex);
      _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
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
    _transformationControllers[_currentIndex]?.value = Matrix4.identity();
    _contentControllers[_currentIndex]?.pause();

    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      setState(() => _currentIndex = prevIndex);
      _pageController.animateToPage(prevIndex, duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
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
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Now';
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
                  final currentScale = _transformationControllers[_currentIndex]?.value.getMaxScaleOnAxis() ?? 1.0;
                  if (currentScale > 1.0) return;
                  if (_isLongPressing) return;

                  _progressController.stop();
                  _progressController.reset();

                  final double screenWidth = MediaQuery.of(context).size.width;
                  final double dx = details.globalPosition.dx;
                  if (dx < screenWidth / 2) {
                    _previousStory();
                  } else {
                    _nextStory();
                  }
                },
                onLongPressStart: (_) {
                  setState(() => _isLongPressing = true);
                  _pauseStory();
                },
                onLongPressEnd: (_) {
                  setState(() => _isLongPressing = false);
                  _resumeStory();
                },
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 100.0, horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stories.length,
                            itemBuilder: (context, index) {
                              final story = _stories[index];
                              _contentControllers.putIfAbsent(index, () => StoryContentController());
                              _transformationControllers.putIfAbsent(index, () => TransformationController());

                              return Hero(
                                tag: widget.heroTag,
                                child: InteractiveViewer(
                                  transformationController: _transformationControllers[index],
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  clipBehavior: Clip.none,
                                  onInteractionStart: (_) => _pauseStory(),
                                  onInteractionEnd: (_) => _resumeStory(),
                                  child: StoryContentView(
                                    key: ValueKey(story.storyId),
                                    story: story,
                                    progressController: _progressController,
                                    controller: _contentControllers[index]!,
                                    onContentLoaded: () {
                                      if (mounted) {
                                        _progressController.stop();
                                        _progressController.reset();
                                        _resumeStory();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
                                Row(
                                  children: [
                                    Text(
                                      widget.userWithStories.username,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimeAgo(currentStory.createdAt),
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.more_horiz, color: Colors.white)),
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
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Send message',
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
                                    const SizedBox(width: 8),
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
}