// lib/components/verified_badge.dart

import 'package:flutter/material.dart';
import 'verified_info_dialog.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  // --- 1. TAMBAHKAN PROPERTI UNTUK MENERIMA URL GAMBAR ---
  final String? profilePictureUrl;

  const VerifiedBadge({
    Key? key,
    this.size = 16.0,
    this.profilePictureUrl, // <-- Jadikan parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 2. BUNGKUS DENGAN MATERIAL DAN INKWELL UNTUK AREA KLIK LEBIH LUAS ---
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Bentuk ripple effect menjadi lingkaran agar terlihat bagus
        borderRadius: BorderRadius.circular(size),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // --- 3. KIRIM URL GAMBAR KE DIALOG ---
              return VerifiedInfoDialog(
                profilePictureUrl: profilePictureUrl,
              );
            },
          );
        },
        child: Padding(
          // Padding ini sekarang berfungsi sebagai area klik tambahan
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.verified,
            color: Colors.blue,
            size: size,
          ),
        ),
      ),
    );
  }
}