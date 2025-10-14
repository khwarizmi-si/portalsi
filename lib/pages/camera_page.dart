import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart'; // <-- IMPORT BARU
import 'edit_post_page.dart'; // <-- IMPORT BARU

enum FlashModeOption { off, auto, on }

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _cameraIndex = 0;

  FlashModeOption _currentFlashMode = FlashModeOption.off;
  String? _lastImagePath;
  bool _isProcessing = false; // <-- State baru untuk loading jepret

  @override
  void initState() {
    super.initState();
    _loadLastImage();
    _initializeCamera();
  }

  Future<void> _loadLastImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastImagePath = prefs.getString('last_captured_image_path');
    });
  }

  Future<void> _saveLastImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_captured_image_path', path);
    setState(() {
      _lastImagePath = path;
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _updateFlashMode();
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;
    await _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    _controller = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _updateFlashMode();
        });
      }
    } catch (e) {
      print("Error saat membalik kamera: $e");
    }
  }

  void _toggleFlashMode() {
    setState(() {
      if (_currentFlashMode == FlashModeOption.off) {
        _currentFlashMode = FlashModeOption.on;
      } else if (_currentFlashMode == FlashModeOption.on) {
        _currentFlashMode = FlashModeOption.auto;
      } else {
        _currentFlashMode = FlashModeOption.off;
      }
      _updateFlashMode();
    });
  }

  void _updateFlashMode() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    switch (_currentFlashMode) {
      case FlashModeOption.off: _controller!.setFlashMode(FlashMode.off); break;
      case FlashModeOption.on: _controller!.setFlashMode(FlashMode.always); break;
      case FlashModeOption.auto: _controller!.setFlashMode(FlashMode.auto); break;
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashModeOption.off: return Icons.flash_off;
      case FlashModeOption.on: return Icons.flash_on;
      case FlashModeOption.auto: return Icons.flash_auto;
    }
  }

  Future<void> _openGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Gambar dipilih dari galeri: ${image.path}');
      // Logika lanjutan setelah memilih dari galeri
    }
  }

  // --- 👇 FUNGSI BARU UNTUK MENGAMBIL FOTO DAN NAVIGASI 👇 ---
  Future<void> _takePictureAndNavigate() async {
    if (_controller?.value.isTakingPicture ?? true) return;

    setState(() { _isProcessing = true; });

    try {
      // 1. Ambil gambar
      final XFile imageFile = await _controller!.takePicture();

      // 2. Minta izin untuk menyimpan ke galeri
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth) {
        // 3. Simpan gambar ke galeri dan dapatkan AssetEntity-nya
        final AssetEntity? assetEntity = await PhotoManager.editor.saveImageWithPath(
          imageFile.path,
          title: "capture_${DateTime.now().millisecondsSinceEpoch}.jpg",
        );

        if (assetEntity != null && mounted) {
          // Simpan path untuk thumbnail di tombol galeri
          await _saveLastImage(imageFile.path);

          // 4. Navigasi ke EditPostPage dengan membawa AssetEntity
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditPostPage(mediaItems: [assetEntity]),
            ),
          );
        }
      } else {
        // Handle jika user menolak izin
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin akses galeri ditolak.'))
        );
      }
    } catch (e) {
      print('Error mengambil foto atau navigasi: $e');
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }
  // --- AKHIR FUNGSI BARU ---


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: size.width,
                  height: size.width * _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),

          // Overlay Gelap di luar Grid
          Positioned.fill(child: CustomPaint(painter: _MaskPainter())),

          // Grid 4:5 di Tengah
          Center(
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: IgnorePointer(
                child: Column(
                  children: [
                    Expanded(child: Row(children: [_buildGridCell(), _buildGridCell(), _buildGridCell()])),
                    Expanded(child: Row(children: [_buildGridCell(), _buildGridCell(), _buildGridCell()])),
                    Expanded(child: Row(children: [_buildGridCell(), _buildGridCell(), _buildGridCell()])),
                  ],
                ),
              ),
            ),
          ),

          // Top Icons
          Positioned(
            top: 50, left: 10, right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(context).pop()),
                IconButton(icon: Icon(_getFlashIcon(), color: Colors.white, size: 30), onPressed: _toggleFlashMode),
                // IconButton(icon: const Icon(Icons.settings, color: Colors.white, size: 30), onPressed: () {}),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ikon Galeri
                  GestureDetector(
                    onTap: _isProcessing ? null : _openGallery,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _lastImagePath != null && File(_lastImagePath!).existsSync()
                            ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gambar latar belakang
                            Positioned(
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: FileImage(File(_lastImagePath!)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Efek tumpukan
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ],
                        )
                            : const Icon(Icons.photo_library, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // Tombol Shutter
                  GestureDetector(
                    onTap: _isProcessing ? null : _takePictureAndNavigate, // <-- PANGGIL FUNGSI BARU DI SINI
                    child: Container(
                      height: 80, width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.9), width: 5),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                            : Container(
                          height: 68, width: 68,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Ikon Balik Kamera
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 30),
                    onPressed: _isProcessing ? null : _flipCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5)),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.4);
    final innerWidth = size.width;
    final innerHeight = size.width / (4 / 5);
    final offsetY = (size.height - innerHeight) / 2;
    final innerRect = Rect.fromLTWH(0, offsetY, innerWidth, innerHeight);
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)), Path()..addRect(innerRect)),
      paint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}