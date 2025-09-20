import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Tetap set false agar tidak loading terus jika error
        });
      }
      // Handle error, misalnya dengan logging
      print("Error generating thumbnail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_thumbnailPath == null) {
      // Tampilkan icon error jika thumbnail gagal dibuat
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    // Tampilkan thumbnail dengan ikon play di atasnya
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Image.file(
          File(_thumbnailPath!),
          fit: BoxFit.cover,
        ),
        // Overlay gelap agar ikon lebih terlihat
        Container(
          color: Colors.black.withOpacity(0.15),
        ),
        const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 40.0,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 10.0,
            )
          ],
        ),
      ],
    );
  }
}