import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../pages/create_story_page.dart';
import '../pages/my_story_view_page.dart';
import '../pages/story_view_page.dart';
import '../services/story_service.dart';
import 'circular_avatar_fetcher.dart';

class StoryCircle extends StatefulWidget {
  final String name;
  final bool isAddStory;
  final bool hasStory;
  final String? imageUrl;
  final String? userProfileUrl; // <-- Parameter ini yang akan kita gunakan
  final User? currentUserData;
  final UserWithStories? userStoryData;
  final List<UserWithStories>? previousStoriesQueue;
  final List<UserWithStories>? nextStoriesQueue;
  final double radius;

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
  }) : super(key: key);

  @override
  _StoryCircleState createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  bool _isLoading = false;
  late bool _isViewed;
  final StoryService _storyService = StoryService();


  @override
  void initState() {
    super.initState();
    _isViewed = widget.userStoryData?.isViewed ?? false;
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

  Future<void> _navigateToViewStory(String heroTag) async {
    if (widget.userStoryData == null || widget.userStoryData!.stories.isEmpty) return;

    if (!_isViewed) {
      setState(() {
        _isViewed = true;
      });
    }

    _storyService.viewStory(widget.userStoryData!.stories.first.storyId).catchError((e) {
      print("Gagal menandai story sebagai dilihat: $e");
      if (mounted) {
        setState(() {
          _isViewed = false;
        });
      }
    });

    setState(() { _isLoading = true; });

    final firstStory = widget.userStoryData!.stories.first;

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
      userStories: const [],
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

  Widget _buildAddStory(BuildContext context, String heroTag) {
    final int userId = widget.currentUserData?.id ?? 0;
    // --- 👇 PERBAIKAN UTAMA DI SINI 👇 ---
    // Sekarang kita menggunakan widget.userProfileUrl yang sudah dikirimkan
    final String? profileUrl = widget.userProfileUrl;
    final bool hasStory = widget.hasStory;
    final bool isViewed = widget.userStoryData?.isViewed ?? true;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CircularAvatarFetcher(
          userId: userId,
          radius: widget.radius,
          onTap: () {
            if (widget.currentUserData != null) {
              _navigateToCreateStory(widget.currentUserData!);
            }
          },
          imageUrl: profileUrl,
          hasStory: hasStory,
          storyViewed: isViewed,
          disableStoryBorder: false,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
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

  Widget _buildOtherStory() {
    final int userId = widget.userStoryData?.userId ?? 0;

    return CircularAvatarFetcher(
      userId: userId,
      radius: widget.radius,
    );
  }

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
                        : GestureDetector(
                      onTap: _isLoading ? null : () => _navigateToViewStory(heroTag),
                      child: _buildOtherStory(),
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    width: avatarSize,
                    height: avatarSize,
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
          ),
          const SizedBox(height: 6),
          Text(widget.name, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1),
        ],
      ),
    );
  }
}