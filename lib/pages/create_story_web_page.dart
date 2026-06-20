// lib/pages/create_story_web_page.dart
//
// ponytail: the mobile create-story page is AssetEntity/PhotoManager-based,
// which don't exist on web. Simple web flow: pick an image, upload its bytes.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';

class CreateStoryWebPage extends StatefulWidget {
  const CreateStoryWebPage({super.key});

  @override
  State<CreateStoryWebPage> createState() => _CreateStoryWebPageState();
}

class _CreateStoryWebPageState extends State<CreateStoryWebPage> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  final _storyService = StoryService();

  Uint8List? _bytes;
  String? _filename;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _filename = file.name;
    });
  }

  Future<void> _submit() async {
    if (_bytes == null) return;
    setState(() => _isUploading = true);
    try {
      await _storyService.createStory(
        {
          'type': 'image',
          'caption': _captionController.text.trim(),
        },
        mediaBytes: _bytes,
        mediaFilename: _filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story berhasil diunggah 🎉')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
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
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54)),
                      onPressed: _pick,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Pilih Foto'),
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
