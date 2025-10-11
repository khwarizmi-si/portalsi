import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../controllers/story_content_controller.dart';
import '../controllers/story_view_controller.dart';
import '../models/story_model.dart';
import '../widgets/story_content_view.dart';
import '../widgets/story_viewers_list.dart';
import 'chat_room.dart';
import '../models/user_model.dart';

class StoryViewPage extends StatefulWidget {
  final int? initialUserId; // Jadikan opsional
  final UserWithStories? initialData;
  final int? initialStoryId;
  final String heroTag;

  const StoryViewPage({
    Key? key,
    this.initialUserId,
    this.initialStoryId,
    this.initialData,
    required this.heroTag,
  }) : super(key: key);

  @override
  _StoryViewPageState createState() => _StoryViewPageState();
}

// lib/pages/story_view_page.dart


class _StoryViewPageState extends State<StoryViewPage> with SingleTickerProviderStateMixin {
  late StoryViewController _controller;

  // State UI lokal
  double _scale = 1.0;
  double _opacity = 1.0;
  final TextEditingController _responseController = TextEditingController();
  final FocusNode _responseFocusNode = FocusNode();
  final Map<int, int> _storyViewCounts = {};

  @override
  void initState() {
    super.initState();
    // --- 👇 PERBAIKAN 2: Inisialisasi controller disesuaikan 👇 ---
    _controller = StoryViewController(
      vsync: this,
      onNextUser: _navigateToNextUser,
      onPreviousUser: _navigateToPreviousUser,
      onComplete: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    // Panggilan ini sekarang aman karena widget.initialUserId tidak mungkin null
    _controller.fetchStoriesForUser(widget.initialUserId, initialStoryId: widget.initialStoryId);

    _responseFocusNode.addListener(() {
      if (_responseFocusNode.hasFocus) {
        _controller.pause(byUI: true);
      } else {
        _controller.resume(byUI: true);
      }
    });
  }

  void _navigateToNextUser(int nextUserId) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: StoryViewPage(
          initialUserId: nextUserId,
          heroTag: 'story_hero_$nextUserId',
        ),
        childCurrent: widget,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToPreviousUser(int prevUserId) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.leftToRight,
        child: StoryViewPage(
          initialUserId: prevUserId,
          heroTag: 'story_hero_$prevUserId',
        ),
        childCurrent: widget,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _responseController.dispose();
    _responseFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<StoryViewController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (controller.userWithStories == null || controller.stories.isEmpty) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Cerita tidak ditemukan atau sudah kedaluwarsa.', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentStory = controller.stories[controller.currentIndex];
          final currentUser = controller.userWithStories!;
          final bool isMyStory = currentUser.userId == controller.currentUser?.id;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Colors.black,
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Dismissible(
                key: Key('story-dismiss-${currentUser.userId}'),
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
                        onTapUp: (details) => controller.handleTap(context, details.globalPosition),
                        onLongPressStart: (_) => controller.pause(byGesture: true),
                        onLongPressEnd: (_) => controller.resume(byGesture: true),
                        child: Stack(
                          children: [
                            _buildBackground(controller),
                            _buildContentView(controller),
                            _buildProgressBars(controller),
                            _buildTopBar(controller),
                            _buildCaption(currentStory),
                            if (isMyStory)
                              _buildMyStoryFooter(context, controller)
                            else
                              _buildStoryResponseInput(context, currentStory, currentUser),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground(StoryViewController controller) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: controller.gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildContentView(StoryViewController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 60.0 + MediaQuery.of(context).padding.top, 16.0, 100.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: PageView.builder(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.stories.length,
          itemBuilder: (context, index) {
            final story = controller.stories[index];
            controller.contentControllers.putIfAbsent(index, () => StoryContentController());
            controller.transformationControllers.putIfAbsent(index, () => TransformationController());
            return Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(
                transformationController: controller.transformationControllers[index],
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                onInteractionStart: (_) => controller.pause(byGesture: true),
                onInteractionEnd: (_) => controller.resume(byGesture: true),
                child: StoryContentView(
                  key: ValueKey(story.storyId),
                  story: story,
                  progressController: controller.progressController,
                  controller: controller.contentControllers[index]!,
                  onContentLoaded: (Duration mediaDuration) {
                    if (mounted) {
                      controller.setVideoDuration(mediaDuration);
                      controller.resume();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBars(StoryViewController controller) {
    return AnimatedBuilder(
      animation: controller.progressController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          right: 10,
          child: Row(
            children: controller.stories.asMap().entries.map((entry) {
              int index = entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: LinearProgressIndicator(
                    value: index == controller.currentIndex
                        ? controller.progressController.value
                        : (index < controller.currentIndex ? 1.0 : 0.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 2.5,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(StoryViewController controller) {
    final currentStory = controller.stories[controller.currentIndex];
    final user = controller.userWithStories!;
    final isMyStory = user.userId == controller.currentUser?.id;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 10,
      right: 10,
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(user.profilePictureUrl)),
          const SizedBox(width: 10),
          Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 8),
          Text(_formatTimeAgo(currentStory.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          if (isMyStory)
            IconButton(onPressed: () => _showMoreOptions(context, controller), icon: const Icon(Icons.more_horiz, color: Colors.white)),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCaption(StoryDetail story) {
    if (story.caption.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 120.0, left: 24.0, right: 24.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16.0)),
        child: Text(story.caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
      ),
    );
  }

  Widget _buildStoryResponseInput(BuildContext context, StoryDetail story, UserWithStories user) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: MediaQuery.of(context).viewInsets.bottom + 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _responseController,
                  focusNode: _responseFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tanggapi cerita ${user.username}...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onChanged: (text) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _responseController.text.isNotEmpty ? () => _navigateToChatRoomWithStoryReply(story, user) : null,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: _responseController.text.isNotEmpty ? Colors.blueAccent : Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyStoryFooter(BuildContext context, StoryViewController controller) {
    final currentStoryId = controller.stories[controller.currentIndex].storyId;
    final viewerCount = _storyViewCounts[currentStoryId]?.toString() ?? '...';
    return Positioned(
      bottom: 20, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterButton(Icons.share, "Kirim ke", onPressed: () {}),
          _buildFooterButton(Icons.alternate_email, "Sebutkan", onPressed: () {}),
          _buildFooterButton(Icons.visibility, "$viewerCount Dilihat", onPressed: () => _showViewersList(context, controller)),
        ],
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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

  void _showViewersList(BuildContext context, StoryViewController controller) {
    final currentStoryId = controller.stories[controller.currentIndex].storyId;
    controller.pause(byUI: true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoryViewersList(
        storyId: currentStoryId,
        onDataLoaded: (totalViewers) {
          if (_storyViewCounts[currentStoryId] != totalViewers) {
            setState(() => _storyViewCounts[currentStoryId] = totalViewers);
          }
        },
      ),
    ).whenComplete(() => controller.resume(byUI: true));
  }

  void _showMoreOptions(BuildContext context, StoryViewController controller) {
    controller.pause(byUI: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final didConfirm = await showDialog<bool>(
                  context: context,
                  builder: (alertContext) => AlertDialog(
                    title: const Text('Hapus Cerita'),
                    content: const Text('Apakah Anda yakin ingin menghapus cerita ini?'),
                    actions: [
                      TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(alertContext).pop(false)),
                      TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(alertContext).pop(true)),
                    ],
                  ),
                );
                if (didConfirm ?? false) {
                  controller.deleteCurrentStory(context);
                }
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => controller.resume(byUI: true));
  }

  void _navigateToChatRoomWithStoryReply(StoryDetail story, UserWithStories user) {
    final text = _responseController.text.trim();
    if (text.isEmpty) return;
    final recipient = User(id: user.userId, username: user.username, profilePictureUrl: user.profilePictureUrl);
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          user: recipient,
          initialReplyText: text,
          initialStoryId: story.storyId,
          initialStoryMediaUrl: story.mediaUrl ?? story.musicAlbumArtUrl,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}h';
    if (duration.inHours > 0) return '${duration.inHours}j';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return 'Baru Saja';
  }
}