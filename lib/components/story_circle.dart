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
    // Cek status izin awal
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

    // Jika semua izin sudah diberikan, langsung lanjutkan
    if (cameraStatus.isGranted && photoStatus.isGranted && microphoneStatus.isGranted) {
      proceedToCreateStory();
      return;
    }

    // Tampilkan dialog izin yang sudah diperbaiki
    bool? wantsToProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // 👇 PERUBAHAN DI SINI: Icon dengan latar gradien
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Gradien untuk latar belakang ikon
              gradient: const LinearGradient(
                colors: [Color(0xFF03B293), Color(0xFF116C63)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40), // Ubah warna ikon menjadi putih
          ),
          title: Text(
            'Izin untuk Membuat Story',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Untuk memberikan pengalaman terbaik, kami memerlukan akses ke:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _buildPermissionRow(Icons.camera_alt_outlined, 'Kamera', 'Untuk merekam foto & video.'),
              _buildPermissionRow(Icons.photo_library_outlined, 'Galeri Foto', 'Untuk memilih dari media yang ada.'),
              _buildPermissionRow(Icons.mic_none_outlined, 'Mikrofon', 'Untuk merekam suara di video.'),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: <Widget>[
            // Aksi dalam bentuk Column agar rapi di layar kecil
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 👇 PERUBAHAN DI SINI: Tombol dengan gradien
                Ink( // Gunakan Ink untuk membungkus Container dengan gradien
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF03B293), Color(0xFF116C63)],
                    ),
                  ),
                  child: InkWell( // InkWell untuk efek tap dan onPressed
                    onTap: () => Navigator.of(dialogContext).pop(true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: const Text(
                        'Lanjutkan & Izinkan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Teks tombol juga putih
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  child: Text('Nanti Saja', style: TextStyle(color: Colors.grey.shade700)),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ],
            ),
          ],
        );
      },
    );

    // Jika pengguna tidak mau melanjutkan, hentikan fungsi
    if (wantsToProceed != true) {
      return;
    }

    // Minta izin
    await [
      Permission.camera,
      Permission.photos,
      Permission.microphone,
    ].request();

    // Cek status izin setelah permintaan
    var newCameraStatus = await Permission.camera.status;
    var newPhotoStatus = await Permission.photos.status;
    var newMicrophoneStatus = await Permission.microphone.status;

    // Jika semua izin diberikan, lanjutkan ke halaman create story
    if (newCameraStatus.isGranted && newPhotoStatus.isGranted && newMicrophoneStatus.isGranted) {
      proceedToCreateStory();
    } else {
      // Jika ada izin yang ditolak, tampilkan snackbar
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

  // 👇 TAMBAHKAN FUNGSI HELPER INI DI DALAM CLASS _StoryCircleState 👇
  Widget _buildPermissionRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade400, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
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