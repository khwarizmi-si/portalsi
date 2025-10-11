// lib/components/verified_info_dialog.dart

import 'package:flutter/material.dart';

class VerifiedInfoDialog extends StatelessWidget {
  // --- 1. TAMBAHKAN PROPERTI UNTUK MENERIMA URL GAMBAR ---
  final String? profilePictureUrl;

  const VerifiedInfoDialog({
    Key? key,
    this.profilePictureUrl, // <-- Jadikan parameter di constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // --- 2. GUNAKAN URL GAMBAR YANG DITERIMA ---
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (profilePictureUrl != null && profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(profilePictureUrl!)
                      : null,
                  child: (profilePictureUrl == null || profilePictureUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  right: -15,
                  bottom: -10,
                  child: Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 50,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Sisa dari widget (Judul, Deskripsi, Footer) tidak berubah
            const Text(
              'Akun Ini Resmi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                children: const <TextSpan>[
                  TextSpan(text: 'Tanda '),
                  TextSpan(text: 'centang biru', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' ini menunjukkan bahwa '),
                  TextSpan(text: 'Portal SI', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' telah melakukan verifikasi terhadap identitas pemilik akun, sehingga Anda dapat lebih yakin bahwa konten yang dibagikan berasal dari sumber yang sah. Dengan demikian, Anda dapat menikmati pengalaman bersosial media yang lebih aman dan terhindar dari informasi palsu atau menyesatkan. Jangan lupa untuk selalu berpikir kritis dan mengecek informasi dari berbagai sumber jika ada keraguan.'),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logopsifull.png', height: 24),
                const SizedBox(width: 8),
                Text('Portal SI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            )
          ],
        ),
      ),
    );
  }
}