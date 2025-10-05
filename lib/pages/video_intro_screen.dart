import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/pages/splash_screen.dart';
import 'package:video_player/video_player.dart';

class VideoIntroScreen extends StatefulWidget {
  const VideoIntroScreen({super.key});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen> {
  late VideoPlayerController _controller;
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    // Sembunyikan UI sistem (status bar, navigation bar) untuk pengalaman layar penuh
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = VideoPlayerController.asset('assets/opening.mp4')
      ..initialize().then((_) {
        // Pastikan frame pertama sudah ditampilkan sebelum memutar video
        setState(() {});
        _controller.play();
      });

    // Tambahkan listener untuk mendeteksi kapan video selesai
    _controller.addListener(_checkVideoEnd);
  }

  void _checkVideoEnd() {
    // Cek apakah video sudah diputar sampai akhir dan navigasi belum dilakukan
    if (_controller.value.position == _controller.value.duration && !_isVideoFinished) {
      setState(() {
        _isVideoFinished = true;
      });
      _navigateToSplash();
    }
  }

  Future<void> _navigateToSplash() async {
    // Hapus listener agar tidak memicu navigasi berulang kali
    _controller.removeListener(_checkVideoEnd);

    // Jeda 1 detik seperti yang diminta
    await Future.delayed(const Duration(seconds: 0));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        // Gunakan PageRouteBuilder untuk membuat transisi kustom
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 10), // Durasi animasi wipe
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // `child` di sini adalah SplashScreen
            return ClipRect(
              clipper: TopWipeClipper(progress: animation.value),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    // Kembalikan UI sistem seperti semula saat halaman ini dihancurkan
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam jika video belum siap
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(), // Tampilkan loading jika video sedang diinisialisasi
      ),
    );
  }
}

// Class Clipper kustom untuk membuat efek wipe dari atas ke bawah
class TopWipeClipper extends CustomClipper<Rect> {
  final double progress; // Nilai dari 0.0 hingga 1.0

  TopWipeClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    // Membuat sebuah persegi yang tingginya berubah sesuai `progress`
    // dari 0 menjadi setinggi `size.height`
    return Rect.fromLTWH(0, 0, size.width, size.height * progress);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true; // Selalu re-clip saat animasi berjalan
  }
}