import 'dart:io';
import 'package:flutter/material.dart';
// ponytail: GoogleMLKit ships no arm64 iOS-simulator binary, so the selfie
// segmenter is dropped here. The page passes the original image through
// unchanged. Restore real cutout by re-adding google_mlkit_selfie_segmentation
// (+ image, path_provider) and running on Android or a physical iOS device.

class CutoutEditorPage extends StatefulWidget {
  final File imageFile;

  const CutoutEditorPage({super.key, required this.imageFile});

  @override
  State<CutoutEditorPage> createState() => _CutoutEditorPageState();
}

class _CutoutEditorPageState extends State<CutoutEditorPage> {
  bool _isProcessing = true;
  File? _cutoutResultFile;
  @override
  void initState() {
    super.initState();
    _processImage();
  }

  // ponytail: pass-through — no MLKit. Returns the original image unchanged.
  Future<void> _processImage() async {
    setState(() {
      _cutoutResultFile = widget.imageFile;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Buat Stiker Cutout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: (_isProcessing || _cutoutResultFile == null)
                ? null
                : () {
              // Kembalikan file hasil cutout ke halaman sebelumnya
              Navigator.of(context).pop(_cutoutResultFile);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.blue, fontSize: 16)),
          )
        ],
      ),
      body: Center(
        child: _isProcessing
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Memproses gambar...', style: TextStyle(color: Colors.white)),
          ],
        )
            : _cutoutResultFile != null
            ? InteractiveViewer(
          child: Image.file(_cutoutResultFile!),
        )
            : const Text('Gagal menampilkan hasil', style: TextStyle(color: Colors.red)),
      ),
    );
  }
}