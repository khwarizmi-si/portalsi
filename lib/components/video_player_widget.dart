import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _videoEnded = false;

  // --- 1. TAMBAHKAN STATE BARU ---
  bool _isMuted = true; // Video dimulai dalam keadaan Mute
  bool _wasPlayingBeforeHold = false;
  bool _showVolumeIcon = false;
  Timer? _volumeIconTimer;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    // ... (kode inisialisasi lainnya tetap sama)
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    await _videoPlayerController.initialize();
    _videoPlayerController.addListener(_videoListener);

    // Set volume awal berdasarkan state _isMuted
    _videoPlayerController.setVolume(_isMuted ? 0.0 : 1.0);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      showControls: false,
      showControlsOnInitialize: false,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  void _videoListener() {
    // ... (listener ini tetap sama)
    final isFinished = _videoPlayerController.value.position >= _videoPlayerController.value.duration;
    if (isFinished && !_videoPlayerController.value.isPlaying && !_videoEnded) {
      if (mounted) setState(() => _videoEnded = true);
    }
  }

  void _replayVideo() {
    // ... (fungsi ini tetap sama)
    setState(() => _videoEnded = false);
    _videoPlayerController.seekTo(Duration.zero).then((_) {
      _videoPlayerController.play();
    });
  }

  // --- 2. FUNGSI BARU UNTUK MUTE/UNMUTE ---
  void _toggleMute() {
    if (_videoEnded) return; // Jangan lakukan apa-apa jika video sudah selesai

    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController.setVolume(_isMuted ? 0.0 : 1.0);

      // Tampilkan ikon volume selama 1 detik
      _showVolumeIcon = true;
    });

    // Sembunyikan ikon setelah 1 detik
    _volumeIconTimer?.cancel();
    _volumeIconTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showVolumeIcon = false);
    });
  }

  @override
  void dispose() {
    // ...
    _volumeIconTimer?.cancel(); // Pastikan timer dibatalkan
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _chewieController == null) {
      // ... (kode loading indicator tetap sama)
      return Container(
        height: 250,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      // --- 3. PERBARUI GESTUREDETECTOR ---
      child: GestureDetector(
        onTap: _toggleMute, // Ganti menjadi toggle mute
        onLongPress: () {
          if (_videoPlayerController.value.isPlaying) {
            _wasPlayingBeforeHold = true;
            _videoPlayerController.pause();
          }
        },
        onLongPressEnd: (_) {
          if (_wasPlayingBeforeHold) {
            _videoPlayerController.play();
            _wasPlayingBeforeHold = false;
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Chewie(controller: _chewieController!),

            // Ikon penanda Mute/Unmute yang muncul saat di-tap
            AnimatedOpacity(
              opacity: _showVolumeIcon ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 40),
              ),
            ),

            // Overlay "Putar Lagi" saat video selesai
            if (_videoEnded)
              Container(
                color: Colors.black.withOpacity(0.6),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pemutaran video telah berakhir.', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Putar Lagi'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.white,
                      ),
                      onPressed: _replayVideo,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}