// lib/pages/splash_screen.dart

import 'package:flutter/foundation.dart' show kIsWeb; // <-- Import untuk cek platform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:portal_si/pages/download_app_prompt_page.dart';
import 'package:portal_si/pages/permissions_page.dart';
import 'package:portal_si/pages/update_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoint.dart';
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

    // Web: validate the stored token before trusting it. A stale/invalid token
    // (e.g. left over from a prod build) must bounce to login, not strand the
    // user on a broken home. (WebSocket/background service aren't used on web.)
    if (kIsWeb) {
      try {
        final res = await http.get(
          Uri.parse('${ApiEndpoints.apiUrl}/user'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/home');
          // Honor a deep link on refresh (/username or /post/:id) by pushing it
          // on top of home, so refreshing a profile/post stays there.
          final path = Uri.base.path;
          if (mounted &&
              path.isNotEmpty &&
              path != '/' &&
              path != '/home') {
            Navigator.of(context).pushNamed(path);
          }
        } else {
          await SecureStorage.deleteToken();
          if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
        }
      } catch (_) {
        await SecureStorage.deleteToken();
        if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
      }
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
        child:Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              width: 80,
              height: 80,
              'assets/logopsifull.png',
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    ),
    );
  }
}