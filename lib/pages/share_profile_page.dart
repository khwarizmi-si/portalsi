// lib/share_profile_page.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// 1. Ubah menjadi StatefulWidget
class ShareProfilePage extends StatefulWidget {
  final String username;

  const ShareProfilePage({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<ShareProfilePage> createState() => _ShareProfilePageState();
}

class _ShareProfilePageState extends State<ShareProfilePage> {
  // 2. Buat GlobalKey untuk menangkap widget kartu QR
  final GlobalKey _qrCardKey = GlobalKey();
  bool _isLoading = false;

  // 3. Buat fungsi untuk setiap aksi tombol

  /// Membuka dialog share sistem untuk membagikan link profil
  void _onShareProfile() {
    final String profileUrl = 'https://www.instagram.com/user/${widget.username}/';
    Share.share('Cek akun Portal SI saya niih! $profileUrl');
  }

  /// Menyalin link profil ke clipboard
  void _onCopyLink() {
    final String profileUrl = 'https://www.portalsi.com/user/${widget.username}/';
    Clipboard.setData(ClipboardData(text: profileUrl)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    });
  }

  Future<void> _onDownload() async {
    // 1. Minta izin menggunakan metode bawaan photo_manager
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo library access is required to save image.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Tangkap widget menjadi gambar (tidak berubah)
      RenderRepaintBoundary boundary = _qrCardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 3. Simpan gambar menggunakan PhotoManager.editor
      final AssetEntity? entity = await PhotoManager.editor.saveImage(
        pngBytes,
        title: 'portalsi_profile_${widget.username}.png', filename: '',
      );

      if (entity != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save QR Code.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while saving.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrData = 'https://www.instagram.com/${widget.username}/';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // title: ActionChip(
        //   label: const Text('COLOR', style: TextStyle(color: Colors.black)),
        //   backgroundColor: Colors.white.withOpacity(0.25),
        //   onPressed: () {
        //     // Logika untuk ganti warna
        //   },
        // ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.all_out_sharp, color: Colors.black, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack( // Gunakan Stack untuk menampilkan indikator loading
        children: [
          Container(
            // Background Gradient
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF0D0), Color(0xFFFFFFFF), Color(0xFFDFFEF8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 4. Bungkus kartu QR dengan RepaintBoundary
                  RepaintBoundary(
                    key: _qrCardKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            // Gambar logo Instagram di tengah QR Code
                            embeddedImage: const AssetImage('assets/instagram_logo.png'), // Pastikan Anda punya file ini
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(40, 40),
                            ),
                            // Warna QR Code
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: Color(0xFFE1306C),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Color(0xFFE1306C),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '@${widget.username}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE1306C),
                              fontFamily: 'InstagramSans', // Gunakan font custom jika ada
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 5. Buat tombol menjadi bisa diklik
                        _buildActionButton(Icons.share, 'Share profile', _onShareProfile),
                        _buildActionButton(Icons.link, 'Copy link', _onCopyLink),
                        _buildActionButton(Icons.download, 'Download', _onDownload),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Indikator loading saat mengunduh
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // 6. Modifikasi helper untuk menerima fungsi onTap
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}