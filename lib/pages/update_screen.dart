// lib/pages/update_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateScreenPage extends StatelessWidget {
  // [UBAH] Tidak lagi menerima URL, tapi menerima fungsi (callback)
  final VoidCallback onUpdateNow;
  final VoidCallback onUpdateLater;

  const UpdateScreenPage({
    super.key,
    required this.onUpdateNow,
    required this.onUpdateLater,
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
            // Ganti dengan path aset Anda yang benar
            Image.asset(
              'assets/images/update_illustration.png',
              height: 200,
            ),
            const SizedBox(height: 48),
            const Text(
              'Pembaruan Tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unduh Versi Terbaru Portal SI di Play Store',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            Text(
              'Pada versi pembaruan terbaru Portal SI, kami melakukan beberapa perubahan yang dapat meningkatkan pengalaman pengguna dan memastikan kenyamanan aplikasi serta fungsionalitas baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: onUpdateNow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent, // <-- UBAH KE TRANSPARAN
                foregroundColor: Colors.white, // Warna foreground tombol (teks)
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0, // <-- HILANGKAN ELEVASI DEFAULT
              ),
              child: Ink( // <-- Gunakan Ink untuk gradient di background
                decoration: BoxDecoration(
                  gradient: const LinearGradient( // <-- Definisikan gradient di sini
                    colors: [
                      Color(0xFFFBBF24), // Warna kuning awal
                      Color(0xFFFF8C00), // Warna oranye akhir
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container( // <-- Tambahkan Container di sini untuk padding teks
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 50), // Pastikan tinggi minimum
                  child: const Text(
                    'Buka PlayStore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // <-- Warna teks putih untuk kontras
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onUpdateLater,
              child: Text(
                'Gunakan Versi Lama Saja',
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