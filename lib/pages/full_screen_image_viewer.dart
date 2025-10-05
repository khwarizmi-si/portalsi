// lib/pages/full_screen_image_viewer.dart

import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final ImageProvider imageProvider;

  // Tambahkan tag hero unik untuk animasi yang mulus (opsional tapi disarankan)
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageProvider,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tombol kembali dengan warna putih agar terlihat di background hitam
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        // InteractiveViewer adalah widget canggih untuk zoom dan pan
        child: InteractiveViewer(
          panEnabled: true, // Izinkan geser
          minScale: 0.5,
          maxScale: 4,     // Batas zoom maksimum 4x
          child: Hero(
            tag: heroTag, // Gunakan tag yang sama dengan di bubble
            child: Image(
              image: imageProvider,
            ),
          ),
        ),
      ),
    );
  }
}