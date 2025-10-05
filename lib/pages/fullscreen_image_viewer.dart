// lib/pages/fullscreen_image_viewer.dart
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Klik di mana saja untuk kembali
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          // InteractiveViewer memungkinkan zoom in/out dengan cubit (pinch)
          child: InteractiveViewer(
            panEnabled: false, // Menonaktifkan geser agar tetap di tengah
            minScale: 1.0,
            maxScale: 4.0,
            child: Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                // Menampilkan loading indicator saat gambar diunduh
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}