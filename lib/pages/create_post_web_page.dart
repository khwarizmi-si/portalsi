// lib/pages/create_post_web_page.dart
//
// ponytail: the mobile create-post page is built on PhotoManager/AssetEntity,
// which don't exist on web. This is a small web-only flow: pick a file via the
// browser dialog (image_picker works on web) and upload the bytes directly,
// skipping the native upload queue.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../services/post_service.dart';

class CreatePostWebPage extends StatefulWidget {
  const CreatePostWebPage({super.key});

  @override
  State<CreatePostWebPage> createState() => _CreatePostWebPageState();
}

class _CreatePostWebPageState extends State<CreatePostWebPage> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  final _postService = PostService();
  final _cropKey = GlobalKey();
  final _transform = TransformationController();

  Uint8List? _bytes;
  String? _filename;
  bool _isVideo = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _transform.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool video}) async {
    final XFile? file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _filename = file.name;
      _isVideo = video;
    });
  }

  /// Render the framed (panned/zoomed) image to PNG bytes so the post matches
  /// what the user composed. Falls back to the original bytes on failure.
  Future<({Uint8List bytes, String name})> _composedImage() async {
    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return (bytes: _bytes!, name: _filename ?? 'post.png');
      final image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return (bytes: _bytes!, name: _filename ?? 'post.png');
      return (bytes: data.buffer.asUint8List(), name: 'post.png');
    } catch (_) {
      return (bytes: _bytes!, name: _filename ?? 'post.png');
    }
  }

  Future<void> _submit() async {
    if (_bytes == null) return;
    setState(() => _isUploading = true);
    try {
      final media = _isVideo
          ? (bytes: _bytes!, name: _filename ?? 'video.mp4')
          : await _composedImage();
      await _postService.createPost(
        {
          'caption': _captionController.text.trim(),
          'is_video': _isVideo ? '1' : '0',
        },
        mediaBytes: media.bytes,
        mediaFilename: media.name,
      );
      if (!mounted) return;
      // Refresh the home feed so the new post shows up immediately.
      try {
        await context.read<HomeController>().refreshDashboardData();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil diunggah 🎉')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _bytes != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text('Buat Postingan'),
        actions: [
          TextButton(
            onPressed: (hasMedia && !_isUploading) ? _submit : null,
            child: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Bagikan',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: !hasMedia
                  ? const Center(
                      child: Text('Belum ada media dipilih',
                          style: TextStyle(color: Colors.grey)))
                  : _isVideo
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(_filename ?? 'video',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      : RepaintBoundary(
                          key: _cropKey,
                          child: ClipRect(
                            child: InteractiveViewer(
                              transformationController: _transform,
                              minScale: 1,
                              maxScale: 4,
                              clipBehavior: Clip.hardEdge,
                              child: Image.memory(_bytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          ),
                        ),
            ),
          ),
          if (hasMedia && !_isVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Geser & cubit untuk atur posisi/ukuran gambar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pick(video: false),
                  icon: const Icon(Icons.photo),
                  label: const Text('Foto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pick(video: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis caption…',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
