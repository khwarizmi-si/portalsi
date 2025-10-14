// lib/pages/create_story_page.dart (UI Web Baru)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../widgets/collage_layout_view.dart';
import '../widgets/music_picker_sheet.dart';
import 'story_preview_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

// --- WIDGET GalleryItemTile (Tidak ada perubahan) ---
class GalleryItemTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GalleryItemTile({
    Key? key,
    required this.asset,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  _GalleryItemTileState createState() => _GalleryItemTileState();
}

class _GalleryItemTileState extends State<GalleryItemTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AssetEntityImage(
                widget.asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(250),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[850],
                    child: const Icon(Icons.error_outline, color: Colors.white),
                  );
                },
              ),
              if (widget.asset.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(widget.asset.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (widget.isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$secs";
  }
}

enum MultiSelectStep { selecting, layoutChoice }

class CreateStoryPage extends StatefulWidget {
  final User currentUser;
  final String heroTag;
  final XFile? initialImage; // Opsional: untuk langsung upload gambar
  final String? initialImageUrl; // Opsional: untuk menampilkan gambar dari URL

  const CreateStoryPage({
    Key? key,
    required this.currentUser,
    required this.heroTag,
    this.initialImage,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  bool _isLoading = true;
  List<AssetEntity> _media = [];
  bool _isSaving = false;
  bool _isMultiSelectMode = false;
  List<AssetEntity> _selectedAssets = [];
  MultiSelectStep _multiSelectStep = MultiSelectStep.selecting;

  @override
  void initState() {
    super.initState();
    // Hanya muat galeri jika bukan di web
    if (!kIsWeb) {
      _loadAlbumsAndRecentMedia();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI BARU UNTUK MENAMPILKAN POPUP DI WEB ---
  Future<void> _showWebMediaPickerPopup() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Media', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Pilih Foto', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _pickMediaForWeb(FileType.image); // Jalankan fungsi pilih gambar
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.white),
                title: const Text('Pilih Video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _pickMediaForWeb(FileType.video); // Jalankan fungsi pilih video
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Fungsi _pickMediaForWeb yang sudah kita buat sebelumnya ---
  Future<void> _pickMediaForWeb(FileType fileType) async {
    // Hanya izinkan gambar untuk saat ini, karena video memerlukan penanganan berbeda di StoryPreviewPage
    if (fileType == FileType.video) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pemilihan video dari file di web belum didukung.")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      // Kita tidak perlu try-catch lagi karena kita tidak memanggil fungsi yang bisa gagal
      final fileBytes = result.files.single.bytes!;

      // Langsung navigasi dan kirim data bytes-nya
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            // Gunakan parameter baru `imageBytes`
            builder: (context) => StoryPreviewPage(imageBytes: fileBytes),
          ),
        );
      }
    }
  }

  // --- Fungsi-fungsi lain tidak banyak berubah ---
  // ... (semua fungsi lain seperti _takePicture, _recordVideo, _showMusicPicker, dll. tetap sama)
  // ...
  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    if (mounted) setState(() => _isSaving = true);

    try {
      AssetEntity? newAsset;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        newAsset = await PhotoManager.editor.saveImage(bytes, filename: image.name);
      } else {
        newAsset = await PhotoManager.editor.saveImageWithPath(
          image.path,
          title: 'story_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (newAsset != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryPreviewPage(assets: [newAsset!]),
          ),
        );
        _loadAlbumsAndRecentMedia();
      }
    } catch (e) {
      print("Error saat menyimpan gambar: $e");
      if (mounted) setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan foto.")),
        );
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _recordVideo() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merekam video tidak didukung di browser.")),
      );
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;
    if (mounted) setState(() => _isSaving = true);

    try {
      final AssetEntity? newAsset = await PhotoManager.editor.saveVideo(
        File(video.path),
        title: 'story_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      if (newAsset != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryPreviewPage(assets: [newAsset!]),
          ),
        );
        _loadAlbumsAndRecentMedia();
      }
    } catch (e) {
      print("Error saat menyimpan video: $e");
      if (mounted) setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan video.")),
        );
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  void _showMusicPicker() async {
    final selectedSong = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicPickerSheet(),
    );

    if (selectedSong != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryPreviewPage(song: selectedSong),
        ),
      );
    }
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Buka Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.white),
                  title: const Text('Rekam Video', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _recordVideo();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadAlbumsAndRecentMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      if (albums.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _albums = albums;
        _selectedAlbum ??= albums.first;
      });
      _loadMediaFromSelectedAlbum();
    } else {
      setState(() => _isLoading = false);
      print("Izin akses galeri ditolak.");
      openAppSettings();
    }
  }

  Future<void> _loadMediaFromSelectedAlbum() async {
    if (_selectedAlbum == null) return;
    setState(() => _isLoading = true);
    final List<AssetEntity> media = await _selectedAlbum!.getAssetListPaged(
      page: 0,
      size: 100,
    );
    setState(() {
      _media = media;
      _isLoading = false;
    });
  }

  void _onItemTap(AssetEntity asset) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedAssets.contains(asset)) {
          _selectedAssets.remove(asset);
          if (_selectedAssets.isEmpty) {
            _isMultiSelectMode = false;
          }
        } else {
          _selectedAssets.add(asset);
        }
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryPreviewPage(assets: [asset]),
        ),
      );
    }
  }

  void _onItemLongPress(AssetEntity asset) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _multiSelectStep = MultiSelectStep.selecting;
        _selectedAssets.add(asset);
      });
    }
  }

  void _cancelMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedAssets.clear();
      _multiSelectStep = MultiSelectStep.selecting;
    });
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isMultiSelectMode) {
          if (_multiSelectStep == MultiSelectStep.layoutChoice) {
            setState(() => _multiSelectStep = MultiSelectStep.selecting);
            return false;
          }
          _cancelMultiSelect();
          return false;
        }
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFDDBC), Colors.white],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(_isMultiSelectMode ? Icons.arrow_back_ios_new : Icons.close, color: Colors.black, size: 24),
                onPressed: () {
                  if (_isMultiSelectMode) {
                    if (_multiSelectStep == MultiSelectStep.layoutChoice) {
                      setState(() => _multiSelectStep = MultiSelectStep.selecting);
                    } else {
                      _cancelMultiSelect();
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                _isMultiSelectMode ? '${_selectedAssets.length} Dipilih' : 'Buat Cerita Anda',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: true,
            ),
            // --- MODIFIKASI UTAMA: TAMPILAN BODY BERBEDA UNTUK WEB DAN MOBILE ---
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : kIsWeb
                ? _buildWebView() // Tampilkan UI Web
                : _buildMobileView(), // Tampilkan UI Mobile
          ),
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK TAMPILAN KHUSUS WEB ---
  Widget _buildWebView() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, color: Colors.grey[700], size: 80),
              const SizedBox(height: 24),
              const Text(
                'Buat Cerita Baru',
                style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih foto atau video dari komputermu.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _showWebMediaPickerPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Pilih dari Perangkat'),
              ),
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text("Memproses...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- WIDGET BARU UNTUK TAMPILAN MOBILE (KODE LAMA ANDA) ---
  Widget _buildMobileView() {
    return Stack(
      children: [
        Column(
          children: [
            if (!(_isMultiSelectMode && _multiSelectStep == MultiSelectStep.layoutChoice))
              _buildTopOptions(),
            if (!(_isMultiSelectMode && _multiSelectStep == MultiSelectStep.layoutChoice))
              _buildRecentsHeader(),
            Expanded(
              child: _media.isEmpty
                  ? const Center(child: Text('Tidak ada media di album ini.', style: TextStyle(color: Colors.white)))
                  : _buildGalleryGrid(),
            ),
          ],
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text("Menyimpan...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _isMultiSelectMode
                ? (_multiSelectStep == MultiSelectStep.selecting
                ? _buildMultiSelectFooter()
                : _buildLayoutChoiceFooter())
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // --- SISA WIDGET BUILDER LAINNYA (TIDAK BERUBAH) ---
  // ...
  Widget _buildRecentsHeader() {
    if (kIsWeb) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          PopupMenuButton<AssetPathEntity>(
            color: Colors.white,
            onSelected: (AssetPathEntity selectedAlbum) {
              setState(() {
                _selectedAlbum = selectedAlbum;
              });
              _loadMediaFromSelectedAlbum();
            },
            itemBuilder: (BuildContext context) {
              return _albums.map((album) {
                return PopupMenuItem<AssetPathEntity>(
                  value: album,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        album.name.isEmpty ? "Tidak Diketahui" : album.name,
                        style: const TextStyle(color: Colors.black),
                      ),
                      if (_selectedAlbum != null && _selectedAlbum!.id == album.id)
                        const Icon(Icons.check, color: Colors.white, size: 20),
                    ],
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedAlbum?.name ?? 'Terbaru',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (!_isMultiSelectMode)
            InkWell(
              onTap: () {
                setState(() => _isMultiSelectMode = true);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, color: Colors.white, size: 20),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (kIsWeb) return const SizedBox.shrink();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _media.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: _showCameraOptions,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 36),
            ),
          );
        }

        final AssetEntity asset = _media[index - 1];

        return GalleryItemTile(
          asset: asset,
          isSelected: _selectedAssets.contains(asset),
          onTap: () => _onItemTap(asset),
          onLongPress: () => _onItemLongPress(asset),
        );
      },
    );
  }

  Widget _buildTopOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildOptionButton(Icons.auto_awesome_mosaic_outlined, 'Template', onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur ini akan segera hadir..',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
          _buildOptionButton(Icons.music_note_outlined, 'Musik', onTap: _showMusicPicker),
        ],
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String label, {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFEDB), Colors.white],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _selectedAssets[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            AssetEntityImage(
                              asset, isOriginal: false, width: 50, height: 50, fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
                                onPressed: () => _onItemTap(asset),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _selectedAssets.length < 2 ? null : () {
                setState(() => _multiSelectStep = MultiSelectStep.layoutChoice);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                children: [
                  Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutChoiceFooter() {
    final bool containsVideo = _selectedAssets.any((asset) => asset.type == AssetType.video);
    final int selectedCount = _selectedAssets.length;
    final bool isLayoutDisabled = containsVideo || selectedCount < 2 || selectedCount > 6;

    String? disabledMessage;
    if (containsVideo) {
      disabledMessage = "Layout tidak mendukung video";
    } else if (isLayoutDisabled) {
      disabledMessage = "Pilih 2-6 gambar untuk Layout";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Opacity(
                          opacity: isLayoutDisabled ? 0.5 : 1.0,
                          child: GestureDetector(
                            onTap: isLayoutDisabled ? null : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StoryPreviewPage(
                                    assets: _selectedAssets,
                                    mode: StoryPreviewMode.layout,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.grey[850],
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CollageLayoutView(assets: _selectedAssets),
                                  Positioned(
                                    bottom: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.grid_on, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          const Text("Kolase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isLayoutDisabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            disabledMessage!,
                            style: TextStyle(color: Colors.yellow[700], fontSize: 12),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StoryPreviewPage(
                              assets: _selectedAssets,
                              mode: StoryPreviewMode.separate,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.grey[850],
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if(_selectedAssets.isNotEmpty)
                              AssetEntityImage(_selectedAssets.last, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              child: const Icon(Icons.autorenew, color: Colors.white, size: 28),
                            ),
                            const Positioned(
                              bottom: 16,
                              child: Text("Terpisah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}