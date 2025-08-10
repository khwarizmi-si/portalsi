// lib/pages/my_story_view_page.dart

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import '../widgets/story_content_view.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../widgets/story_viewers_list.dart';
import 'story_view_page.dart';

class MentionUser {
  final String username;
  final String fullName;
  final String avatarUrl;

  MentionUser({required this.username, required this.fullName, required this.avatarUrl});
}

class MyStoryViewPage extends StatefulWidget {
  final UserWithStories userWithStories;
  final String heroTag;
  final List<UserWithStories>? nextStories;
  final List<UserWithStories>? previousStories;

  const MyStoryViewPage({
    Key? key,
    required this.userWithStories,
    required this.heroTag,
    this.nextStories,
    this.previousStories,
  }) : super(key: key);

  @override
  _MyStoryViewPageState createState() => _MyStoryViewPageState();
}

class _MyStoryViewPageState extends State<MyStoryViewPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isSheetOpen = false;
  bool _isLoadingContent = true;
  final StoryService _storyService = StoryService();
  late List<StoryDetail> _stories;

  // State untuk gestur dismiss
  double _scale = 1.0;
  double _opacity = 1.0;

  final List<MentionUser> _mentionableUsers = [
    MentionUser(username: 'darkxwolf17._.-_', fullName: 'mra774r', avatarUrl: 'https://i.pravatar.cc/150?img=1'),
    MentionUser(username: 'danzgocrazy', fullName: 'DanzAlone', avatarUrl: 'https://i.pravatar.cc/150?img=2'),
  ];
  List<MentionUser> _selectedMentions = [];

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

    // Halaman ini sekarang HANYA mendengarkan kapan progress selesai
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
    super.dispose(); // Hanya ada satu super.dispose()
  }

  void _nextStory() {
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
            duration: const Duration(milliseconds: 600),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteStory() async {
    Navigator.of(context).pop();

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Cerita'),
          content: const Text('Apakah Anda yakin ingin menghapus cerita ini?'),
          actions: <Widget>[
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghapus...')));
      final storyToDelete = _stories[_currentIndex];
      final bool success = await _storyService.deleteStory(storyToDelete.storyId);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        setState(() {
          _stories.removeAt(_currentIndex);
        });

        if (_stories.isEmpty) {
          Navigator.of(context).pop();
        } else {
          final newIndex = _currentIndex.clamp(0, _stories.length - 1);
          // Cukup update UI, PageView akan membangun StoryContentView yang benar
          _pageController.jumpToPage(newIndex);
          setState(() => _currentIndex = newIndex);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus cerita.')));
      }
    }
  }

  void _showViewersActivity() {
    // Jeda timer cerita
    _progressController.stop();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Viewers',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: StoryViewersList(),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Animasi slide dari bawah
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    ).whenComplete(() {
      // Lanjutkan timer setelah ditutup
      if (!_isSheetOpen) { // Pastikan tidak ada sheet lain yang terbuka
        _progressController.forward();
      }
    });
  }

  void _showMoreOptions() {
    setState(() => _isSheetOpen = true);
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.insights, color: Colors.white),
                title: const Text('Aktivitas', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Tutup bottom sheet "More"
                  _showViewersActivity();     // Buka sheet "Aktivitas"
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.white),
                title: const Text('Simpan Foto', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  print('Simpan Foto diklik');
                },
              ),
              ListTile(
                leading: const Icon(Icons.speaker_notes_off_outlined, color: Colors.white),
                title: const Text('Matikan Komentar', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  print('Matikan Komentar diklik');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                onTap: _handleDeleteStory,
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() => _isSheetOpen = false);
      _progressController.forward();
    });
  }

  void _showMentionSheet() {
    setState(() => _isSheetOpen = true);
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Container(
                  // ... UI Mention Sheet
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _isSheetOpen = false);
      if(!_isLoadingContent) _progressController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Dismissible(
        key: const Key('my-story-dismissible'),
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
                          return Hero(
                            tag: widget.heroTag,
                            child: StoryContentView(
                              key: ValueKey(story.storyId),
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
                                          value: entry.key == _currentIndex ? _progressController.value : (entry.key < _currentIndex ? 1.0 : 0.0),
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
                                Text(
                                  widget.userWithStories.username,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                          color: Colors.black.withOpacity(0.4),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Say something...',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 1),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildFooterButton(Icons.share, "Share to"),
                                    _buildFooterButton(Icons.ios_share, "Share on..."),
                                    _buildFooterButton(Icons.alternate_email, "Mention", onPressed: _showMentionSheet),
                                    _buildFooterButton(Icons.more_horiz, "More", onPressed: _showMoreOptions),
                                  ],
                                ),
                              )
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

  Widget _buildFooterButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed ?? () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}