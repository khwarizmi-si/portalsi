import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ZoomableImageOverlay extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const ZoomableImageOverlay({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<ZoomableImageOverlay> createState() => _ZoomableImageOverlayState();
}

class _ZoomableImageOverlayState extends State<ZoomableImageOverlay> {
  // 1. Buat TransformationController untuk mengontrol zoom & pan secara manual
  final _transformationController = TransformationController();

  // 2. Fungsi untuk mereset zoom
  void _resetZoom() {
    // Mengatur matriks transformasi kembali ke posisi awal (identitas)
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(
                transformationController: _transformationController, // Hubungkan controller
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 1.0, // Skala minimum adalah ukuran asli
                maxScale: 4.0,
                // 3. Panggil fungsi reset saat interaksi berakhir
                onInteractionEnd: (details) {
                  // Fungsi ini akan dipanggil saat Anda mengangkat jari
                  _resetZoom();
                },
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error, color: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}