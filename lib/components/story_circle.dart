// lib/widgets/story_circle.dart

import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../pages/create_story_page.dart';
import '../pages/my_story_view_page.dart';
import '../pages/story_view_page.dart';

class StoryCircle extends StatefulWidget {
  final String name;
  final bool isAddStory;
  final bool hasStory;
  final String? imageUrl;
  final String? userProfileUrl;
  final UserWithStories? userStoryData;
  final List<UserWithStories>? previousStoriesQueue;
  final List<UserWithStories>? nextStoriesQueue;

  const StoryCircle({
    Key? key,
    required this.name,
    this.isAddStory = false,
    this.hasStory = false,
    this.imageUrl,
    this.userProfileUrl,
    this.userStoryData,
    this.nextStoriesQueue,
    this.previousStoriesQueue,
  }) : super(key: key);

  @override
  _StoryCircleState createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  bool _isLoading = false;

  Route _createSlideRightRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const CreateStoryPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  void _navigateToCreateStory() {
    Navigator.of(context).push(_createSlideRightRoute());
  }

  // --- FUNGSI INI DIPERBAIKI ---
  Future<void> _navigateToViewStory(String heroTag) async {
    if (widget.userStoryData == null || widget.userStoryData!.stories.isEmpty) return;

    setState(() { _isLoading = true; });

    final firstStory = widget.userStoryData!.stories.first;

    // PERBAIKAN: Hanya precache jika mediaUrl tidak null dan bukan video
    if (!firstStory.isVideo && firstStory.mediaUrl != null) {
      await precacheImage(NetworkImage(firstStory.mediaUrl!), context);
    }

    if (!mounted) return;
    setState(() { _isLoading = false; });

    final pageToPush = widget.isAddStory
        ? MyStoryViewPage(
      userWithStories: widget.userStoryData!,
      heroTag: heroTag,
      previousStories: widget.previousStoriesQueue,
      nextStories: widget.nextStoriesQueue,
      userStories: [],
    )
        : StoryViewPage(
      userWithStories: widget.userStoryData!,
      heroTag: heroTag,
      previousStories: widget.previousStoriesQueue,
      nextStories: widget.nextStoriesQueue,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => pageToPush,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildAddStoryNoContent(BuildContext context, String heroTag) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.hasStory ? () => _navigateToViewStory(heroTag) : _navigateToCreateStory,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  widget.userProfileUrl ?? 'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: _navigateToCreateStory,
            child: _buildAddButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddStoryWithContent(BuildContext context, String heroTag) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _navigateToViewStory(heroTag),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: NetworkImage(
                      widget.userProfileUrl ?? 'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: _navigateToCreateStory,
            child: _buildAddButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    );
  }

  Widget _buildOtherStory() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: DecorationImage(
              image: NetworkImage(widget.imageUrl ?? 'https://via.placeholder.com/150'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'story_hero_${widget.userStoryData?.userId ?? widget.name}';

    return widget.isAddStory
        ? Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Hero(
                tag: heroTag,
                child: widget.hasStory
                    ? _buildAddStoryWithContent(context, heroTag)
                    : _buildAddStoryNoContent(context, heroTag),
              ),
              if (_isLoading)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.name, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1),
        ],
      ),
    )
        : GestureDetector(
      onTap: _isLoading ? null : () => _navigateToViewStory(heroTag),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Hero(tag: heroTag, child: _buildOtherStory()),
                if (_isLoading)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.name, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1),
          ],
        ),
      ),
    );
  }
}