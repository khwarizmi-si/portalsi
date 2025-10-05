// lib/pages/my_story_view_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:share_plus/share_plus.dart';
import '../components/post_card.dart';
import '../controllers/story_content_controller.dart';
import '../services/follow_service.dart';
import '../widgets/story_content_view.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../widgets/story_viewers_list.dart';
import 'story_view_page.dart';


class ShareUser {
  final String name;
  final String avatarUrl;

  ShareUser({required this.name, required this.avatarUrl});
}

// Controller untuk komunikasi antara halaman ini dengan kontennya (StoryContentView).
// Ini memungkinkan halaman untuk mengirim perintah 'pause' atau 'resume' ke video/musik di dalam konten.
// class StoryContentController {
//   VoidCallback? _pauseListener;
//   VoidCallback? _resumeListener;
//
//   void addListeners({VoidCallback? onPause, VoidCallback? onResume}) {
//     _pauseListener = onPause;
//     _resumeListener = onResume;
//   }
//
//   void pause() => _pauseListener?.call();
//   void resume() => _resumeListener?.call();
//   void dispose() {
//     _pauseListener = null;
//     _resumeListener = null;
//   }
// }

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
  final List<dynamic> userStories;

  const MyStoryViewPage({
    Key? key,
    required this.userWithStories,
    required this.heroTag,
    this.nextStories,
    this.previousStories,
    required this.userStories,
  }) : super(key: key);

  @override
  _MyStoryViewPageState createState() => _MyStoryViewPageState();
}

class _MyStoryViewPageState extends State<MyStoryViewPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isSheetOpen = false;
  bool _isLongPressing = false;

  final StoryService _storyService = StoryService();
  late List<StoryDetail> _stories;

  final Map<int, StoryContentController> _contentControllers = {};
  // Map untuk mengelola state zoom setiap story
  final Map<int, TransformationController> _transformationControllers = {};

  List<ShareUser> _shareableUsers = [];
  final List<ShareUser> _selectedUsers = [];
  bool _isLoadingUsers = false;

  final FollowService _followService = FollowService();



  // State untuk gestur dismiss
  double _scale = 1.0;
  double _opacity = 1.0;

  List<ShareUser> _filteredUsers = [];
  String _searchQuery = '';

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
      return;
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
    // Hapus juga semua transformation controller
    _transformationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _pauseStory() {
    _progressController.stop();
    _contentControllers[_currentIndex]?.pause();
  }

  void _resumeStory() {
    if (mounted && !_isSheetOpen && !_isLongPressing) {
      // Cek juga apakah story sedang di-zoom atau tidak
      final currentScale = _transformationControllers[_currentIndex]?.value.getMaxScaleOnAxis() ?? 1.0;
      if (currentScale <= 1.0) {
        _progressController.forward();
        _contentControllers[_currentIndex]?.resume();
      }
    }
  }

  void _nextStory() {
    // Reset zoom story saat ini sebelum pindah
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

  void _onShareStory() {
    // final previousUserData = widget.previousStories!.last;
    final String storyUrl = 'https://www.portalsi.com/user/${widget.userWithStories.userId}/story/${_currentIndex}/';
    Share.share('Weee!! cek story gua nih!! $storyUrl');
  }

  void _previousStory() {
    // Reset zoom story saat ini sebelum pindah
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
          _pageController.jumpToPage(newIndex);
          setState(() => _currentIndex = newIndex);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus cerita.')));
      }
    }
  }

  void _showViewersActivity() {
    setState(() => _isSheetOpen = true);
    _pauseStory();

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
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    ).whenComplete(() {
      setState(() => _isSheetOpen = false);
      _resumeStory();
    });
  }

  void _showMoreOptions() {
    setState(() => _isSheetOpen = true);
    _pauseStory();

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
                  Navigator.of(context).pop();
                  _showViewersActivity();
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
      // 2. Setelah sheet ditutup, tandai bahwa sheet sudah tidak ada
      //    dan PANGGIL FUNGSI LANJUTKAN UTAMA
      setState(() => _isSheetOpen = false);
      _resumeStory();
    });
  }

  void _showMentionSheet() {
    setState(() => _isSheetOpen = true);
    _pauseStory();

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
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "People added here will be mentioned in your story but their username won't be visible.",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _mentionableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _mentionableUsers[index];
                            final bool isSelected = _selectedMentions.contains(user);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              title: Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(user.fullName, style: TextStyle(color: Colors.grey[400])),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      _selectedMentions.add(user);
                                    } else {
                                      _selectedMentions.remove(user);
                                    }
                                  });
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                                side: BorderSide(color: Colors.grey[600]!),
                              ),
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    _selectedMentions.remove(user);
                                  } else {
                                    _selectedMentions.add(user);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedMentions.isNotEmpty ? () {
                              print('${_selectedMentions.length} pengguna di-mention');
                              Navigator.of(context).pop();
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              disabledBackgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _isSheetOpen = false);
      _resumeStory();
    });
  }

  // Di dalam class _MyStoryViewPageState di file lib/pages/my_story_view_page.dart

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final StoryDetail currentStory = _stories[_currentIndex];
    final imageUrl = widget.userWithStories.profilePictureUrl;

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
                  if (_isLongPressing) return;

                  _progressController.stop();
                  _progressController.reset();

                  final double screenWidth = MediaQuery.of(context).size.width;
                  final double dx = details.globalPosition.dx;
                  if (dx < screenWidth / 2) { // Cukup bagi dua layar untuk navigasi
                    _previousStory();
                  } else {
                    _nextStory();
                  }
                },
                // MODIFIKASI: Gunakan fungsi pause/resume terpusat
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
                              // MODIFIKASI: Buat dan berikan controller ke StoryContentView
                              _contentControllers.putIfAbsent(index, () => StoryContentController());
                              return Hero(
                                tag: widget.heroTag,
                                child: StoryContentView(
                                  key: ValueKey(story.storyId),
                                  story: story,
                                  progressController: _progressController,
                                  controller: _contentControllers[index]!, // Berikan controller
                                  onContentLoaded: () {
                                    if (mounted) {
                                      // MODIFIKASI: Gunakan _resumeStory agar konsisten
                                      _progressController.stop();
                                      _progressController.reset();
                                      _resumeStory();
                                    }
                                  },
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
                                  backgroundColor: Colors.grey.shade400, // Warna latar belakang jika tidak ada gambar
                                  // Gunakan kondisi: jika imageUrl tidak null & tidak kosong, baru gunakan NetworkImage
                                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  // Jika tidak ada gambar, tampilkan ikon sebagai gantinya
                                  child: (imageUrl == null || imageUrl.isEmpty)
                                      ? const Icon(Icons.person, size: 22, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    // _buildFooterButton(Icons.share, "Kirim ke", onPressed: _showShareOnSheet),
                                    _buildFooterButton(Icons.share, "Kirim ke", onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Fitur ini akan segera hadir..',
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    // _buildFooterButton(Icons.alternate_email, "Sebutkan", onPressed: _showMentionSheet),
                                    _buildFooterButton(Icons.alternate_email, "Sebutkan", onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Fitur ini akan segera hadir..',
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    _buildFooterButton(Icons.more_horiz, "Lainnya", onPressed: _showMoreOptions),
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

  Widget _buildFooterButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed ?? () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // GANTI SELURUH FUNGSI INI DI my_story_view_page.dart

  Future<void> _fetchFollowingUsers() async {
    if (_shareableUsers.isNotEmpty && mounted) {
      setState(() => _isLoadingUsers = false);
      return;
    }

    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final myProfile = await _followService.getMyProfile();
      final myUserId = myProfile['id'] ?? myProfile['user_id'];

      if (myUserId != null) {
        // MODIFIKASI: Ubah myUserId menjadi String sebelum dikirim
        final followingList = await _followService.getFollowing(myUserId.toString());

        print('====== RESPONSE DARI API [getFollowing] ======');
        print(followingList);
        print('============================================');

        final users = followingList.map((user) {
          // BENAR: Gunakan notasi titik untuk mengakses properti objek User
          final avatarUrl = user.profilePictureUrl ?? 'https://via.placeholder.com/150';
          return ShareUser(
            name: user.username, // <-- Ganti di sini
            avatarUrl: avatarUrl, // <-- Dan di sini (jika ada)
          );
        }).toList();

        if (mounted) {
          setState(() {
            _shareableUsers = users;
          });
        }
      } else {
        throw Exception("User ID tidak ditemukan dari getMyProfile()");
      }
    } catch (e) {
      print("Error fetching following users: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pengguna: $e')),
        );
        setState(() {
          _shareableUsers = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  // MODIFIKASI: Ubah fungsi ini menjadi `async`
  Future<void> _showShareOnSheet() async {
    setState(() => _isSheetOpen = true);
    _pauseStory();

    // BARU: Panggil fungsi fetch data sebelum menampilkan sheet
    await _fetchFollowingUsers();

    _selectedUsers.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Drag Handle, Search Bar...
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                              onPressed: () {},
                            )
                          ],
                        ),
                      ),

                      // MODIFIKASI: Tampilkan loading atau Grid Pengguna
                      Expanded(
                        child: _isLoadingUsers
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1 / 1.2,
                          ),
                          itemCount: _shareableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _shareableUsers[index];
                            final bool isSelected = _selectedUsers.contains(user);

                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    _selectedUsers.remove(user);
                                  } else {
                                    _selectedUsers.add(user);
                                  }
                                });
                              },
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(user.avatarUrl),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withOpacity(0.5),
                                            border: Border.all(color: Colors.blue, width: 2),
                                          ),
                                          child: const Icon(Icons.check, color: Colors.white),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      if (_selectedUsers.isNotEmpty)
                        _buildShareFooter(),

                      if (_selectedUsers.isEmpty)
                        _buildShareActionRow(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _isSheetOpen = false);
      _resumeStory();
    });
  }

  Widget _buildShareActionRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _buildShareActionItem(Icons.share, 'Bagikan', Colors.grey.shade800, onPressed: _onShareStory),
            _buildShareActionItem(Icons.ios_share, 'Publik', Colors.green),
            _buildShareActionItem(Icons.link, 'Salin Tautan', Colors.blue),
            _buildShareActionItem(Icons.sms, 'SMS', Colors.lightBlue),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // MODIFIKASI: Buat widget baru untuk footer yang muncul saat user dipilih
  Widget _buildShareFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade700, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Write a message...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    print('Send separately to ${_selectedUsers.length} users');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Send separately', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Tampilkan tumpukan avatar yang dipilih
              Stack(
                children: List.generate(
                  _selectedUsers.length.clamp(0, 3), // Tampilkan maks 3 avatar
                      (index) => Padding(
                    padding: EdgeInsets.only(left: (index * 15.0)),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(_selectedUsers[index].avatarUrl),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  print('Create group with ${_selectedUsers.length} users');
                },
                child: const Text('Create group', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8), // Padding bawah
        ],
      ),
    );
  }
  // BARU: Helper widget untuk membangun item di deretan aksi bawah
  // MODIFIKASI: Tambahkan parameter {VoidCallback? onPressed}
  Widget _buildShareActionItem(IconData icon, String label, Color color, {VoidCallback? onPressed}) {
    // MODIFIKASI: Bungkus dengan InkWell agar bisa diklik
    return InkWell(
      onTap: onPressed, // Gunakan parameter onPressed di sini
      borderRadius: BorderRadius.circular(40), // Agar efek riak membulat
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}