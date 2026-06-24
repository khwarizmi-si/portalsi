// lib/components/video_thumbnail_widget.dart

import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoThumbnailWidget(
      {super.key, required this.videoUrl, this.thumbnailUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late Future<String?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = kIsWeb ? Future.value(null) : _generateThumbnail();
  }

  Future<String?> _generateThumbnail() async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        maxWidth: 150,
        quality: 50,
      );
      return thumbnailPath;
    } catch (e) {
      log("🚨 Gagal membuat thumbnail: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }

    if (kIsWeb) return _placeholder();

    return FutureBuilder<String?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
          );
        } else if (snapshot.hasError) {
          return _placeholder();
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.play_circle_fill, color: Colors.grey[600], size: 42),
      ),
    );
  }
}
