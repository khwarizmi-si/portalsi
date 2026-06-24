// lib/pages/create_story_web_page.dart
//
// ponytail: the mobile create-story page is AssetEntity/PhotoManager-based,
// which don't exist on web. Simple web flow: pick media, upload its bytes.
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../services/story_service.dart';

class CreateStoryWebPage extends StatefulWidget {
  const CreateStoryWebPage({super.key});

  @override
  State<CreateStoryWebPage> createState() => _CreateStoryWebPageState();
}

class _CreateStoryWebPageState extends State<CreateStoryWebPage> {
  final _captionController = TextEditingController();
  final _storyService = StoryService();

  Uint8List? _bytes;
  String? _filename;
  bool _isVideo = false;
  bool _isUploading = false;
  double? _uploadProgress;
  String? _pickError;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool video}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions:
          video ? const ['mp4', 'mov', 'webm'] : const ['jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null) return;
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _pickError = 'File tidak bisa dibaca oleh browser.');
      return;
    }
    setState(() {
      _bytes = bytes;
      _filename = file.name.isNotEmpty
          ? file.name
          : (video ? 'story.mp4' : 'story.png');
      _isVideo = video;
      _pickError = null;
    });
  }

  Future<void> _submit() async {
    if (_bytes == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      await _storyService.createStory(
        {
          'type': _isVideo ? 'video' : 'image',
          'caption': _captionController.text.trim(),
        },
        mediaBytes: _bytes,
        mediaFilename: _filename,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _uploadProgress = (sent / total).clamp(0.0, 1.0));
        },
      );
      if (!mounted) return;
      try {
        await context.read<HomeController>().refreshDashboardData();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story berhasil diunggah 🎉')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mengunggah story: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _bytes != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Buat Story'),
        actions: [
          TextButton(
            onPressed: (hasMedia && !_isUploading) ? _submit : null,
            child: _isUploading
                ? Text(
                    '${((_uploadProgress ?? 0) * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : const Text('Bagikan',
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: !hasMedia
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54)),
                          onPressed: () => _pick(video: false),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Pilih Foto'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54)),
                          onPressed: () => _pick(video: true),
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Pilih Video'),
                        ),
                        if (_pickError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _pickError!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    )
                  : _isVideo
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam,
                                color: Colors.white70, size: 72),
                            const SizedBox(height: 8),
                            Text(
                              _filename ?? 'video',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : InteractiveViewer(
                          child: Image.memory(_bytes!, fit: BoxFit.contain),
                        ),
            ),
          ),
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tulis caption…',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
