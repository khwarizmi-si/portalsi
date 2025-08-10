// lib/widgets/story_circle.dart

import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../pages/create_story_page.dart';
import '../pages/my_story_view_page.dart';
import '../pages/story_view_page.dart';
import '../pages/my_story_view_page.dart';

class StoryCircle extends StatefulWidget {
  // ... (properti tetap sama)
  final String name;
  final bool isAddStory;
  final bool hasStory;
  final String? imageUrl;
  final String? userProfileUrl;
  final UserWithStories? userStoryData;
  final List<UserWithStories>? previousStoriesQueue;

  const StoryCircle({
    Key? key,
    required this.name,
    this.isAddStory = false,
    this.hasStory = false,
    this.imageUrl,
    this.userProfileUrl,
    this.userStoryData,
    this.nextStoriesQueue, // <-- TAMBAHKAN DI CONSTRUCTOR
    this.previousStoriesQueue,
  }) : super(key: key);

  final List<UserWithStories>? nextStoriesQueue; // <-- PROPERTI BARU

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

  Future<void> _navigateToViewStory(String heroTag) async {
    if (widget.userStoryData == null || widget.userStoryData!.stories.isEmpty) return;

    setState(() { _isLoading = true; });

    final firstStory = widget.userStoryData!.stories.first;
    if (!firstStory.isVideo) {
      await precacheImage(NetworkImage(firstStory.mediaUrl), context);
    }

    if (!mounted) return;
    setState(() { _isLoading = false; });

    // Tentukan halaman mana yang akan dibuka berdasarkan properti isAddStory
    final pageToPush = widget.isAddStory
        ? MyStoryViewPage(
      userWithStories: widget.userStoryData!,
      heroTag: heroTag,
      previousStories: widget.previousStoriesQueue, // <-- Teruskan antrean
      nextStories: widget.nextStoriesQueue,
    )
        : StoryViewPage(
      userWithStories: widget.userStoryData!,
      heroTag: heroTag,
      previousStories: widget.previousStoriesQueue, // <-- Teruskan antrean
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

  // --- SEMUA FUNGSI _build... DIMODIFIKASI UNTUK MEMILIKI AKSI KLIK TERPISAH ---

  Widget _buildAddStoryNoContent(BuildContext context, String heroTag) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gesture Detector untuk gambar profil (jika ada cerita)
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
        // Gesture Detector untuk tombol tambah
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
      // ... (kode UI tidak berubah)
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

    // GestureDetector hanya untuk cerita pengguna lain
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
              // ... (Loading Indicator)
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
                // ... (Loading Indicator)
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