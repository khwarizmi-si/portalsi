// lib/pages/download_app_prompt_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadAppPromptPage extends StatelessWidget {
  final String playStoreUrl;
  final VoidCallback onContinueToWeb;

  const DownloadAppPromptPage({
    super.key,
    required this.playStoreUrl,
    required this.onContinueToWeb,
  });

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
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ganti dengan path ilustrasi Anda yang sesuai
            Image.asset(
              'assets/images/download_app_illustration.png',
              height: 250,
            ),
            const SizedBox(height: 48),
            const Text(
              'Portal SI tersedia\ndi PlayStore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ayo download Portal SI di PlayStore untuk mengakses fitur yang lebih baik, dan banyak!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            // Tombol Buka PlayStore dengan Gradient
            ElevatedButton(
              onPressed: () {
                launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero, // Hapus padding default
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Buka PlayStore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tombol Lanjutkan ke Website
            TextButton(
              onPressed: onContinueToWeb,
              child: Text(
                'Lanjutkan dengan menggunakan Website',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }
}