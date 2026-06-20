import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CutoutEditorPage extends StatefulWidget {
  final File imageFile;

  const CutoutEditorPage({super.key, required this.imageFile});

  @override
  State<CutoutEditorPage> createState() => _CutoutEditorPageState();
}

class _CutoutEditorPageState extends State<CutoutEditorPage> {
  bool _isProcessing = true;
  File? _cutoutResultFile;
  late final SelfieSegmenter _segmenter;

  @override
  void initState() {
    super.initState();
    _segmenter = SelfieSegmenter(mode: SegmenterMode.stream);
    _processImage();
  }

  @override
  void dispose() {
    _segmenter.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFile(widget.imageFile);
      final mask = await _segmenter.processImage(inputImage);

      if (mask == null) {
        throw Exception('Gagal mendapatkan segmentation mask.');
      }

      // Gunakan 'image' package untuk memanipulasi piksel
      final originalImageBytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalImageBytes);

      if (originalImage == null) {
        throw Exception('Gagal membaca gambar.');
      }

      // Buat gambar baru yang transparan
      final cutoutImage = img.Image(width: mask.width, height: mask.height);

      for (int y = 0; y < mask.height; y++) {
        for (int x = 0; x < mask.width; x++) {
          // Dapatkan nilai confidence dari mask (0.0 - 1.0)
          final confidence = mask.confidences[y * mask.width + x];

          // Jika confidence > 0.8 (artinya bagian dari orang), salin piksel asli.
          // Jika tidak, piksel akan tetap transparan (default).
          if (confidence > 0.8) {
            cutoutImage.setPixel(x, y, originalImage.getPixel(x, y));
          }
        }
      }

      // Simpan hasil cutout ke file baru
      final tempDir = await getTemporaryDirectory();
      final cutoutFilePath = '${tempDir.path}/cutout_${DateTime.now().millisecondsSinceEpoch}.png';
      final cutoutFile = File(cutoutFilePath);

      // Encode ke format PNG yang mendukung transparansi
      await cutoutFile.writeAsBytes(img.encodePng(cutoutImage));

      setState(() {
        _cutoutResultFile = cutoutFile;
        _isProcessing = false;
      });

    } catch (e) {
      print("Error saat membuat cutout: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat cutout: $e')));
        Navigator.of(context).pop(); // Kembali jika error
      }
    }
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