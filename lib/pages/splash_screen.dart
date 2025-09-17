// lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import '../managers/cache_manager.dart';
import '../services/auth_service.dart'; // Gantilah dengan path AuthService Anda yang benar
import '../utils/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Cek apakah ada token (sesi login aktif)
    final String? token = await SecureStorage.getToken();

    // Jeda singkat untuk branding (opsional)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (token != null) {
      // 2. JIKA ADA TOKEN: Lakukan semua proses inisialisasi di sini
      print('🚀 Sesi aktif ditemukan. Menginisialisasi semua service...');
      try {
        // Inisialisasi WebSocket (INI YANG PALING PENTING)
        AuthService.initializeWebSocket(token);

        // Inisialisasi CacheManager yang sebelumnya ada di main()
        CacheManager.initialize();

        // Preload data penting yang sebelumnya ada di _initializeAppData()
        await CacheManager.preloadCriticalData();

        print('✅ Inisialisasi selesai. Masuk ke aplikasi.');
        // Navigasi ke halaman utama
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        print('❌ Gagal inisialisasi: $e. Arahkan ke halaman login.');
        // Jika ada error saat inisialisasi, lempar ke login
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } else {
      // 3. JIKA TIDAK ADA TOKEN: Langsung ke halaman welcome/login
      print('Sesi tidak ditemukan. Arahkan ke halaman welcome.');
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI sederhana untuk Splash Screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Ganti dengan logo aplikasi Anda
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                width: 80,
                height: 80,
                'assets/logopsifull.png'
            ), // Logo aplikasi Anda
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}