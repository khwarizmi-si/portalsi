// lib/pages/splash_screen.dart

import 'package:flutter/foundation.dart' show kIsWeb; // <-- Import untuk cek platform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:portal_si/pages/download_app_prompt_page.dart';
import 'package:portal_si/pages/permissions_page.dart';
import 'package:portal_si/pages/update_screen.dart';
import 'package:upgrader/upgrader.dart';
import '../managers/cache_manager.dart';
import '../services/auth_service.dart';
import '../utils/secure_storage.dart';
import '../services/message_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Definisikan URL Play Store di satu tempat
  final String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.portal.si';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (kIsWeb) {
      // _showDownloadPrompt();
      _continueToApp();
    } else {
      // --- PERUBAHAN UTAMA: PANGGIL PENGECEKAN IZIN ---
      _handlePermissions();
    }
  }

  // [FUNGSI BARU] Untuk menangani alur permintaan izin
  Future<void> _handlePermissions() async {
    // Cek status izin notifikasi, foto, dan video
    final statusNotification = await Permission.notification.status;
    final statusPhotos = await Permission.photos.status;
    final statusVideos = await Permission.videos.status;

    // Jika salah satu saja belum diizinkan, buka halaman permintaan izin
    if (statusNotification.isDenied || statusPhotos.isDenied || statusVideos.isDenied) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PermissionsPage(
              onPermissionsGranted: () {
                // Setelah izin diberikan, lanjutkan ke pengecekan update
                _checkAppUpdate();
              },
            ),
          ),
        );
      }
    } else {
      // Jika semua izin sudah ada, langsung lanjutkan ke pengecekan update
      _checkAppUpdate();
    }
  }

  // [NAMA FUNGSI DIUBAH] untuk kejelasan
  void _showDownloadPrompt() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadAppPromptPage(
          playStoreUrl: playStoreUrl,
          onContinueToWeb: () {
            _continueToApp();
          },
        ),
      ),
    );
  }

  Future<void> _checkAppUpdate() async {
    final upgrader = Upgrader(
      appcastConfig: AppcastConfiguration(
        url: playStoreUrl, // Gunakan URL yang sudah didefinisikan
        supportedOS: ['android'],
      ),
      debugLogging: true,
    );

    await upgrader.initialize();
    if (!mounted) return;

    if (upgrader.isUpdateAvailable()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateScreenPage(
            onUpdateNow: () => upgrader.sendUserToAppStore(),
            onUpdateLater: () => _continueToApp(),
          ),
        ),
      );
    } else {
      _continueToApp();
    }
  }

  // Fungsi ini berisi logika inisialisasi aplikasi Anda
  Future<void> _continueToApp() async {
    final String? token = await SecureStorage.getToken();
    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
      return;
    }

    // Jika platform web dan token ada, langsung masuk ke /home
    // (WebSocket, background service, dll tidak didukung di web)
    if (kIsWeb) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    try {
      print('🚀 Sesi aktif ditemukan. Menginisialisasi semua service...');

      final chatService = ChatService();
      final channels = await chatService.getActiveConversationChannels();

      if (channels.isNotEmpty && AuthService.webSocketService != null) {
        for (final channelName in channels) {
          AuthService.webSocketService!.subscribeToChannel(channelName);
        }
      }

      CacheManager.initialize();
      await CacheManager.preloadCriticalData();

      print('✅ Inisialisasi selesai. Masuk ke aplikasi.');
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('❌ Gagal inisialisasi: $e. Arahkan ke halaman login.');
      if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dengan animasi fade-in sederhana
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/logopsifull.png',
                    width: 90,
                    height: 90,
                  ),
                ),
                const SizedBox(height: 28),
                // Loading indicator yang lebih halus
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: const Color(0xFFF97C33),
                    backgroundColor: Colors.orange.shade50,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}