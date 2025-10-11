// lib/components/story_circle.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../pages/create_story_page.dart';
import '../services/story_service.dart';
import 'circular_avatar_fetcher.dart'; // Pastikan ini di-import

class StoryCircle extends StatefulWidget {
  final String name;
  final bool isAddStory;
  final bool hasStory;
  final String? imageUrl;
  final String? userProfileUrl;
  final User? currentUserData;
  final UserWithStories? userStoryData;
  final List<UserWithStories>? previousStoriesQueue;
  final List<UserWithStories>? nextStoriesQueue;
  final double radius;
  final int? currentUserId;
  final List<Color>? prefetchedColors;
  final VoidCallback? onStoryClosed;

  const StoryCircle({
    Key? key,
    required this.name,
    this.isAddStory = false,
    this.hasStory = false,
    this.imageUrl,
    this.currentUserData,
    this.userProfileUrl,
    this.userStoryData,
    this.nextStoriesQueue,
    this.previousStoriesQueue,
    this.radius = 24.0,
    this.currentUserId,
    this.prefetchedColors,
    this.onStoryClosed,
  }) : super(key: key);

  @override
  _StoryCircleState createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  // --- initState() dan _navigateToCreateStory() tidak ada perubahan ---
  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToCreateStory(User user) async {
    var cameraStatus = await Permission.camera.status;
    var photoStatus = await Permission.photos.status;
    var microphoneStatus = await Permission.microphone.status;

    final heroTag = 'story_create_avatar_${user.id}';

    void proceedToCreateStory() {
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CreateStoryPage(
            currentUser: user,
            heroTag: heroTag,
            initialImageUrl: user.profilePictureUrl,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }

    if (cameraStatus.isGranted && photoStatus.isGranted && microphoneStatus.isGranted) {
      proceedToCreateStory();
      return;
    }

    bool? wantsToProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Butuh Izin Anda'),
          content: const Text('Untuk membuat Story, kami butuh izin untuk mengakses Kamera, Galeri Foto, dan Mikrofon Anda. Izinkan akses?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Nanti Saja'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Izinkan', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (wantsToProceed != true) {
      return;
    }

    await [
      Permission.camera,
      Permission.photos,
      Permission.microphone,
    ].request();

    var newCameraStatus = await Permission.camera.status;
    var newPhotoStatus = await Permission.photos.status;
    var newMicrophoneStatus = await Permission.microphone.status;

    if (newCameraStatus.isGranted && newPhotoStatus.isGranted && newMicrophoneStatus.isGranted) {
      proceedToCreateStory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin ditolak. Silakan aktifkan melalui Pengaturan Aplikasi.'),
          action: SnackBarAction(
            label: 'PENGATURAN',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }


  // --- 👇 PERBAIKAN UTAMA ADA DI FUNGSI INI 👇 ---
  Widget _buildAddStory(BuildContext context, String heroTag) {
    final int userId = widget.currentUserData?.id ?? 0;
    final String? profileUrl = widget.userProfileUrl;
    final bool hasStory = widget.hasStory;
    final bool isViewed = widget.userStoryData?.isViewed ?? false; // Default ke false jika null

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 1. Avatar utama yang menampilkan border cerita (gradien/abu-abu)
        CircularAvatarFetcher(
          userId: userId,
          radius: widget.radius,
          // Jika punya story, onTap-nya null agar bisa membuka story viewer.
          // Jika tidak punya, onTap akan membuka story creator.
          onTap: hasStory
              ? null
              : () {
            if (widget.currentUserData != null) {
              _navigateToCreateStory(widget.currentUserData!);
            }
          },
          onStoryClosed: widget.onStoryClosed, // Tetap teruskan untuk refresh
          imageUrl: profileUrl,
          hasStory: hasStory,
          storyViewed: isViewed,
          disableStoryBorder: false,
          currentUserId: widget.currentUserId,
          previousStoriesQueue: widget.previousStoriesQueue,
          nextStoriesQueue: widget.nextStoriesQueue,
          prefetchedColors: widget.prefetchedColors,
        ),

        // 2. Tombol plus (+) yang selalu tampil
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            // Tombol plus ini akan selalu membuka halaman create story
            onTap: () {
              if (widget.currentUserData != null) {
                _navigateToCreateStory(widget.currentUserData!);
              }
            },
            child: _buildAddButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    const double buttonSize = 30;
    const double iconSize = 22;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF03B293),
            Color(0xFF116C63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFAFAFA), width: 2),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: iconSize),
    );
  }

  // --- _buildOtherStory() tidak ada perubahan ---
  Widget _buildOtherStory() {
    final int userId = widget.userStoryData?.userId ?? 0;

    return CircularAvatarFetcher(
      userId: userId,
      radius: widget.radius,
      imageUrl: widget.imageUrl,
      hasStory: widget.userStoryData?.stories.isNotEmpty,
      currentUserId: widget.currentUserId,
      previousStoriesQueue: widget.previousStoriesQueue,
      nextStoriesQueue: widget.nextStoriesQueue,
      prefetchedColors: widget.prefetchedColors,
      onStoryClosed: widget.onStoryClosed,
    );
  }

  // --- build() tidak ada perubahan ---
  @override
  Widget build(BuildContext context) {
    final double avatarSize = widget.radius * 2 + 10;
    final heroTag = widget.isAddStory
        ? 'story_hero_add_story'
        : 'story_hero_${widget.userStoryData?.userId ?? widget.name}';

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: heroTag,
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: widget.isAddStory
                        ? _buildAddStory(context, heroTag)
                        : _buildOtherStory(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.name, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1),
        ],
      ),
    );
  }
}