// lib/pages/create_story_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../models/song_model.dart';
import '../widgets/collage_layout_view.dart'; // Pastikan path ini benar
import '../widgets/music_picker_sheet.dart';
import 'story_preview_page.dart';
import 'package:flutter/services.dart';
import 'camera_settings_page.dart';

// --- WIDGET BARU UNTUK SETIAP ITEM GALERI ---
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
  const CreateStoryPage({super.key});

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
    _loadAlbumsAndRecentMedia();
  }

  void _showMusicPicker() async {
    // Hentikan musik yang mungkin masih berjalan dari pratinjau sebelumnya
    // (Jika Anda punya state management global untuk audio)

    // Tunggu hasil dari bottom sheet
    final selectedSong = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicPickerSheet(),
    );

    // Jika pengguna memilih lagu (hasilnya tidak null)
    if (selectedSong != null && mounted) {
      // Navigasi ke StoryPreviewPage dengan data lagu
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

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    if (mounted) setState(() => _isSaving = true);

    try {
      final AssetEntity? newAsset = await PhotoManager.editor.saveImageWithPath(
        image.path,
        title: 'story_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (mounted) setState(() => _isSaving = false);

      if (newAsset != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryPreviewPage(assets: [newAsset]),
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
    }
  }

  Future<void> _recordVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;
    if (mounted) setState(() => _isSaving = true);

    try {
      final AssetEntity? newAsset = await PhotoManager.editor.saveVideo(
        File(video.path),
        title: 'story_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      if (mounted) setState(() => _isSaving = false);

      if (newAsset != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryPreviewPage(assets: [newAsset]),
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
    }
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
          systemNavigationBarColor: Color(0xFF1A1A1A),
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Color(0xFF1A1A1A),
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            leading: IconButton(
              icon: Icon(_isMultiSelectMode ? Icons.arrow_back_ios_new : Icons.close, color: Colors.white, size: 24),
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
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              if (!_isMultiSelectMode)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                  onPressed: () {
                    // Gunakan PageRouteBuilder untuk animasi slide dari bawah
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const CameraSettingsPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          // Tentukan posisi awal (di bawah layar) dan akhir (di layar)
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;

                          // Buat transisi
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  if (!(_isMultiSelectMode && _multiSelectStep == MultiSelectStep.layoutChoice))
                    _buildTopOptions(),
                  if (!(_isMultiSelectMode && _multiSelectStep == MultiSelectStep.layoutChoice))
                    _buildRecentsHeader(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _media.isEmpty
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
          ),
        ),
      ),
    );
  }

  Widget _buildTopOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildOptionButton(Icons.auto_awesome_mosaic_outlined, 'Template', onTap: () {  }),
          const SizedBox(width: 12),
          _buildOptionButton(Icons.music_note_outlined, 'Musik', onTap: _showMusicPicker),
        ],
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String label, {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap, // Gunakan onTap dari parameter
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          PopupMenuButton<AssetPathEntity>(
            color: const Color(0xFF2C2C2E),
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
                        album.name.isEmpty ? "Unknown" : album.name,
                        style: const TextStyle(color: Colors.white),
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
                    _selectedAlbum?.name ?? 'Recents',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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

  // --- FUNGSI INI SEKARANG DIMODIFIKASI UNTUK VALIDASI ---
  Widget _buildLayoutChoiceFooter() {
    // Cek apakah ada video di dalam item yang dipilih
    final bool containsVideo = _selectedAssets.any((asset) => asset.type == AssetType.video);
    // Cek jumlah item yang dipilih
    final int selectedCount = _selectedAssets.length;
    // Kondisi disabled: ada video ATAU jumlah item di luar rentang 2-6
    final bool isLayoutDisabled = containsVideo || selectedCount < 2 || selectedCount > 6;

    // Tentukan pesan error jika disabled
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
                // Kartu "Layout"
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
                      // Tampilkan pesan error jika disabled
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
                // Kartu "Separate"
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